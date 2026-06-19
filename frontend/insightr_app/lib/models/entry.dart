import 'action_item.dart';

/// Full zone-structured entry from GET /api/entries/{id}
class Entry {
  final int id;
  final String title;
  final String sourceUrl;
  final String field;
  final List<String> tags;
  final String contentType;
  final String createdAt;

  // Zone 1 — The Grab
  final ZoneGrab zoneGrab;

  // Zone 2 — The Substance
  final ZoneSubstance zoneSubstance;

  // Zone 3 — The Deep End
  final ZoneDeep zoneDeep;

  const Entry({
    required this.id,
    required this.title,
    required this.sourceUrl,
    required this.field,
    required this.tags,
    required this.contentType,
    required this.createdAt,
    required this.zoneGrab,
    required this.zoneSubstance,
    required this.zoneDeep,
  });

  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      sourceUrl: json['source_url'] as String? ?? '',
      field: json['field'] as String? ?? '',
      tags: List<String>.from(json['tags'] as List? ?? []),
      contentType: json['content_type'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      zoneGrab: ZoneGrab.fromJson(json['zone_grab'] as Map<String, dynamic>? ?? {}),
      zoneSubstance: ZoneSubstance.fromJson(json['zone_substance'] as Map<String, dynamic>? ?? {}),
      zoneDeep: ZoneDeep.fromJson(json['zone_deep'] as Map<String, dynamic>? ?? {}),
    );
  }
}

// ─── Zone 1 ─────────────────────────────────────────────────────────────────

class ZoneGrab {
  final String hook;
  final String nextStep;
  final ActionItem? topAction;

  const ZoneGrab({
    required this.hook,
    required this.nextStep,
    this.topAction,
  });

  factory ZoneGrab.fromJson(Map<String, dynamic> json) {
    return ZoneGrab(
      hook: json['hook'] as String? ?? '',
      nextStep: json['next_step'] as String? ?? '',
      topAction: json['top_action'] != null
          ? ActionItem.fromJson(json['top_action'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ─── Zone 2 ─────────────────────────────────────────────────────────────────

class ZoneSubstance {
  final List<NoteBlock> noteBlocks;
  final List<ActionItem> actionItems;

  const ZoneSubstance({
    required this.noteBlocks,
    required this.actionItems,
  });

  factory ZoneSubstance.fromJson(Map<String, dynamic> json) {
    return ZoneSubstance(
      noteBlocks: (json['note_blocks'] as List? ?? [])
          .map((b) => NoteBlock.fromJson(b as Map<String, dynamic>))
          .toList(),
      actionItems: (json['action_items'] as List? ?? [])
          .map((a) => ActionItem.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

class NoteBlock {
  final String blockType;
  final String? title;
  final String content;

  const NoteBlock({
    required this.blockType,
    this.title,
    required this.content,
  });

  factory NoteBlock.fromJson(Map<String, dynamic> json) {
    return NoteBlock(
      blockType: json['block_type'] as String? ?? 'text',
      title: json['title'] as String?,
      content: json['content'] as String? ?? '',
    );
  }
}

// ─── Zone 3 ─────────────────────────────────────────────────────────────────

class ZoneDeep {
  final List<KnowledgeCard> knowledgeCards;
  final List<ReferencedArtifact> referencedArtifacts;
  final List<Connection> connections;

  const ZoneDeep({
    required this.knowledgeCards,
    required this.referencedArtifacts,
    required this.connections,
  });

  factory ZoneDeep.fromJson(Map<String, dynamic> json) {
    return ZoneDeep(
      knowledgeCards: (json['knowledge_cards'] as List? ?? [])
          .map((k) => KnowledgeCard.fromJson(k as Map<String, dynamic>))
          .toList(),
      referencedArtifacts: (json['referenced_artifacts'] as List? ?? [])
          .map((r) => ReferencedArtifact.fromJson(r as Map<String, dynamic>))
          .toList(),
      connections: (json['connections'] as List? ?? [])
          .map((c) => Connection.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class KnowledgeCard {
  final int id;
  final String conceptType;
  final String name;
  final String summary;

  const KnowledgeCard({
    required this.id,
    required this.conceptType,
    required this.name,
    required this.summary,
  });

  factory KnowledgeCard.fromJson(Map<String, dynamic> json) {
    return KnowledgeCard(
      id: json['id'] as int? ?? 0,
      conceptType: json['concept_type'] as String? ?? '',
      name: json['name'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
    );
  }
}

class ReferencedArtifact {
  final String name;
  final String type;
  final String description;
  final String? url;
  final String? snippet;

  const ReferencedArtifact({
    required this.name,
    required this.type,
    required this.description,
    this.url,
    this.snippet,
  });

  factory ReferencedArtifact.fromJson(Map<String, dynamic> json) {
    return ReferencedArtifact(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      description: json['description'] as String? ?? '',
      url: json['url'] as String?,
      snippet: json['snippet'] as String?,
    );
  }
}

class Connection {
  final int entryId;
  final String title;
  final String reason;

  const Connection({required this.entryId, required this.title, required this.reason});

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      entryId: json['entry_id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
    );
  }
}
