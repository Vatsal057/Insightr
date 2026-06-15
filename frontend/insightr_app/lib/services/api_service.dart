import 'dart:convert';
import 'package:http/http.dart' as http;

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
  final _base = AppConstants.baseUrl;

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Map<String, String> get _jsonHeaders => {'Content-Type': 'application/json'};

  Future<dynamic> _get(String path, {Map<String, String>? params}) async {
    final uri = Uri.parse('$_base$path').replace(queryParameters: params);
    final response = await _client.get(uri, headers: _jsonHeaders);
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
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, response.body);
    }
    return jsonDecode(response.body);
  }

  // ─── Feed & Entries ───────────────────────────────────────────────────────

  Future<List<FeedCard>> getFeed({int limit = AppConstants.feedLimit}) async {
    final data = await _get(
      AppConstants.feedEndpoint,
      params: {'limit': limit.toString()},
    ) as List;
    return data
        .map((e) => FeedCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Entry> getEntry(int id) async {
    final data = await _get('${AppConstants.entriesEndpoint}/$id');
    return Entry.fromJson(data as Map<String, dynamic>);
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
    final data =
        await _post(AppConstants.processEndpoint, {'url': url});
    return (data as Map<String, dynamic>)['task_id'] as String? ?? '';
  }

  Future<ProcessStatus> pollStatus(String taskId) async {
    final data =
        await _get('${AppConstants.statusEndpoint}/$taskId');
    return ProcessStatus.fromJson(data as Map<String, dynamic>);
  }

  // ─── Action Items ─────────────────────────────────────────────────────────

  Future<List<ActionItem>> getTodo({bool? done}) async {
    final params = done != null ? {'done': done.toString()} : null;
    final data = await _get(AppConstants.todoEndpoint, params: params) as List;
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
    final data = await _get(AppConstants.collectionsEndpoint) as List;
    return data
        .map((e) => Collection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createCollection(String name, int entryId) async {
    await _post(AppConstants.collectionsEndpoint,
        {'name': name, 'entry_id': entryId.toString()});
  }

  Future<List<FeedCard>> getCollectionEntries(String name) async {
    final data =
        await _get('${AppConstants.collectionsEndpoint}/$name') as List;
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
    final uri =
        Uri.parse('$_base${AppConstants.exportEndpoint}/collection/$name');
    final response = await _client.get(uri);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, response.body);
    }
    return response.body;
  }

  /// Bulk export the entire vault in the specified format.
  /// format: 'markdown' | 'notion' | 'json' | 'csv'
  Future<void> export({required String format}) async {
    final uri = Uri.parse('$_base${AppConstants.exportEndpoint}')
        .replace(queryParameters: {'format': format});
    final response = await _client.get(uri);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, response.body);
    }
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
