import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:multicast_dns/multicast_dns.dart';

import '../core/constants.dart';
import '../models/action_item.dart';
import '../models/collection.dart';
import '../models/concept.dart';
import '../models/entry.dart';
import '../models/feed_card.dart';

/// Processing status returned by GET /api/status/{task_id}
class ProcessStatus {
  final String status; // "processing" | "completed" | "failed"
  final int? entryId;
  final String? error;

  const ProcessStatus({required this.status, this.entryId, this.error});

  factory ProcessStatus.fromJson(Map<String, dynamic> json) {
    return ProcessStatus(
      status: json['status'] as String? ?? 'processing',
      entryId: json['entry_id'] as int?,
      error: json['error'] as String?,
    );
  }
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _client = http.Client();
  String _base = AppConstants.baseUrl;
  String _username = '';

  String get username => _username;

  void setUsername(String name) {
    _username = name.trim().toLowerCase();
  }

  Future<void> initialize() async {
    // Attempt UDP broadcast discovery
    RawDatagramSocket? udpSocket;
    try {
      udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 8888);
      udpSocket.broadcastEnabled = true;
      debugPrint('Listening for UDP broadcasts on port 8888...');

      bool found = false;

      final discoveryFuture = udpSocket.firstWhere((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = udpSocket!.receive();
          if (datagram != null) {
            final message = utf8.decode(datagram.data);
            if (message.startsWith('INSIGHTR_BACKEND|')) {
              final parts = message.split('|');
              if (parts.length >= 3) {
                final ip = parts[1];
                final port = parts[2];
                _base = 'http://$ip:$port';
                debugPrint('Found Insightr Backend via UDP at $_base');
                found = true;
                return true;
              }
            }
          }
        }
        return false;
      }).timeout(const Duration(seconds: 3));

      await discoveryFuture;
      if (found) return;
    } catch (e) {
      if (e is TimeoutException) {
        debugPrint('UDP discovery timed out, falling back to mDNS');
      } else {
        debugPrint('UDP discovery failed: $e');
      }
    } finally {
      // Always release the socket — without this, a timeout or any thrown
      // error left port 8888 bound for the lifetime of the app, which could
      // cause "address already in use" failures on the next hot restart.
      udpSocket?.close();
    }

    try {
      final MDnsClient client = MDnsClient();
      await client.start();

      final String name = '_insightr._tcp.local';

      await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(
          ResourceRecordQuery.serverPointer(name), timeout: const Duration(seconds: 2))) {
        await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
            ResourceRecordQuery.service(ptr.domainName))) {
          await for (final IPAddressResourceRecord ip in client.lookup<IPAddressResourceRecord>(
              ResourceRecordQuery.addressIPv4(srv.target))) {
            _base = 'http://${ip.address.address}:${srv.port}';
            debugPrint('Found Insightr Backend via mDNS at $_base');
            client.stop();
            return;
          }
        }
      }
      client.stop();
    } catch (e) {
      debugPrint('mDNS discovery failed: $e');
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Map<String, String> get _jsonHeaders => {'Content-Type': 'application/json'};

  Future<dynamic> _get(String path, {Map<String, String>? params}) async {
    final uri = Uri.parse('$_base$path').replace(queryParameters: params);
    final response = await _client.get(uri, headers: _jsonHeaders).timeout(const Duration(seconds: 5));
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, response.body);
    }
    return jsonDecode(response.body);
  }

  Future<dynamic> _post(String path, Map<String, String> formData) async {
    final uri = Uri.parse('$_base$path');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: formData,
    ).timeout(const Duration(seconds: 5));
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, response.body);
    }
    return jsonDecode(response.body);
  }

  Future<dynamic> _postLong(String path, Map<String, String> formData) async {
    final uri = Uri.parse('$_base$path');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: formData,
    ).timeout(const Duration(seconds: 60));
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, response.body);
    }
    return jsonDecode(response.body);
  }

  // ─── Feed & Entries ───────────────────────────────────────────────────────

  /// Registers or logs in a user. Returns the user_id.
  Future<int> register(String username) async {
    final data = await _post(AppConstants.registerEndpoint, {'username': username});
    _username = (data as Map<String, dynamic>)['username'] as String? ?? username;
    return data['user_id'] as int;
  }

  Future<List<FeedCard>> getFeed({int limit = AppConstants.feedLimit}) async {
    final params = <String, String>{'limit': limit.toString()};
    if (_username.isNotEmpty) params['username'] = _username;
    final data = await _get(AppConstants.feedEndpoint, params: params) as List;
    return data
        .map((e) => FeedCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Entry> getEntry(int id) async {
    final data = await _get('${AppConstants.entriesEndpoint}/$id');
    return Entry.fromJson(data as Map<String, dynamic>);
  }

  Future<bool> toggleFavorite(int entryId, bool isFavorite) async {
    final data = await _post(
      '${AppConstants.entriesEndpoint}/$entryId/favorite',
      {'favorite': isFavorite.toString()},
    );
    return (data as Map<String, dynamic>)['is_favorite'] as bool? ?? false;
  }

  Future<bool> toggleImplementing(int entryId, bool isImplementing) async {
    final data = await _post(
      '${AppConstants.entriesEndpoint}/$entryId/implement',
      {'implement': isImplementing.toString()},
    );
    return (data as Map<String, dynamic>)['is_implementing'] as bool? ?? false;
  }

  Future<String> getDeepResearchPrompt(int id) async {
    final data =
        await _get('${AppConstants.entriesEndpoint}/$id/deep-research-prompt');
    return (data as Map<String, dynamic>)['deep_research_prompt'] as String? ??
        '';
  }

  // ─── Processing ───────────────────────────────────────────────────────────

  /// Returns a task_id to poll with [pollStatus].
  Future<String> processUrl(String url) async {
    final formData = <String, String>{'url': url};
    if (_username.isNotEmpty) formData['username'] = _username;
    final data = await _postLong(AppConstants.processEndpoint, formData);
    return (data as Map<String, dynamic>)['task_id'] as String? ?? '';
  }

  Future<ProcessStatus> pollStatus(String taskId) async {
    final data =
        await _get('${AppConstants.statusEndpoint}/$taskId');
    return ProcessStatus.fromJson(data as Map<String, dynamic>);
  }

  // ─── Action Items ─────────────────────────────────────────────────────────

  Future<List<ActionItem>> getTodo({bool? done}) async {
    final params = <String, String>{};
    if (done != null) params['done'] = done.toString();
    if (_username.isNotEmpty) params['username'] = _username;
    final data = await _get(AppConstants.todoEndpoint, params: params.isEmpty ? null : params) as List;
    return data
        .map((e) => ActionItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> toggleTodo(int itemId, {required bool done}) async {
    await _post(
      '${AppConstants.todoEndpoint}/$itemId/check',
      {'done': done.toString()},
    );
  }

  // ─── Search ───────────────────────────────────────────────────────────────

  Future<List<FeedCard>> search(String q,
      {String? tag, String? field, String? contentType}) async {
    final params = <String, String>{'q': q};
    if (tag != null) params['tag'] = tag;
    if (field != null) params['field'] = field;
    if (contentType != null) params['content_type'] = contentType;
    if (_username.isNotEmpty) params['username'] = _username;

    final data =
        await _get(AppConstants.searchEndpoint, params: params) as List;
    return data
        .map((e) => FeedCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Knowledge Cards / Concepts ───────────────────────────────────────────

  Future<List<Concept>> getConcepts(
      {String? conceptType, String? query}) async {
    final params = <String, String>{};
    if (conceptType != null) params['concept_type'] = conceptType;
    if (query != null) params['query'] = query;

    final data =
        await _get(AppConstants.conceptsEndpoint, params: params.isEmpty ? null : params)
            as List;
    return data
        .map((e) => Concept.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FeedCard>> getConceptEntries(int conceptId) async {
    final data =
        await _get('${AppConstants.conceptsEndpoint}/$conceptId/entries')
            as List;
    return data
        .map((e) => FeedCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Collections ─────────────────────────────────────────────────────────

  Future<List<Collection>> getCollections() async {
    final params = <String, String>{};
    if (_username.isNotEmpty) params['username'] = _username;
    final data = await _get(AppConstants.collectionsEndpoint, params: params.isEmpty ? null : params) as List;
    return data
        .map((e) => Collection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createCollection(String name, int entryId) async {
    final formData = <String, String>{'name': name, 'entry_id': entryId.toString()};
    if (_username.isNotEmpty) formData['username'] = _username;
    await _post(AppConstants.collectionsEndpoint, formData);
  }

  Future<List<FeedCard>> getCollectionEntries(String name) async {
    final data = await _get(
            '${AppConstants.collectionsEndpoint}/${Uri.encodeComponent(name)}')
        as List;
    return data
        .map((e) => FeedCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Export ───────────────────────────────────────────────────────────────

  Future<String> exportEntry(int id) async {
    final uri = Uri.parse('$_base${AppConstants.exportEndpoint}/$id');
    final response = await _client.get(uri);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, response.body);
    }
    return response.body;
  }

  Future<String> exportCollection(String name) async {
    final uri = Uri.parse(
        '$_base${AppConstants.exportEndpoint}/collection/${Uri.encodeComponent(name)}');
    final response = await _client.get(uri);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, response.body);
    }
    return response.body;
  }

  /// Export the entire vault as Markdown — GET /api/export?format=markdown
  Future<String> exportVault() async {
    final uri = Uri.parse('$_base${AppConstants.exportEndpoint}')
        .replace(queryParameters: {'format': 'markdown'});
    final response = await _client.get(uri).timeout(const Duration(seconds: 30));
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, response.body);
    }
    return response.body;
  }

  void dispose() => _client.close();
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}
