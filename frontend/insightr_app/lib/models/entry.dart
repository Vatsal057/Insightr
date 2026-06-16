import 'action_item.dart';
import 'feed_card.dart';

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
  final EffortPill? effortPill;

  const ZoneGrab({
    required this.hook,
    required this.nextStep,
    this.topAction,
    this.effortPill,
  });

  factory ZoneGrab.fromJson(Map<String, dynamic> json) {
    return ZoneGrab(
      hook: json['hook'] as String? ?? '',
      nextStep: json['next_step'] as String? ?? '',
      topAction: json['top_action'] != null
          ? ActionItem.fromJson(json['top_action'] as Map<String, dynamic>)
          : null,
      effortPill: json['effort_pill'] != null
          ? EffortPill.fromJson(json['effort_pill'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ─── Zone 2 ─────────────────────────────────────────────────────────────────

class ZoneSubstance {
  final CoreTakeaway? coreTakeaway;
  final List<NoteBlock> noteBlocks;
  final List<ActionItem> actionItems;
  final String keyPoints;
  final List<ToolResource> toolsResources;
  final List<ImplementationStep> implementationPlan;

  const ZoneSubstance({
    this.coreTakeaway,
    required this.noteBlocks,
    required this.actionItems,
    required this.keyPoints,
    required this.toolsResources,
    required this.implementationPlan,
  });

  factory ZoneSubstance.fromJson(Map<String, dynamic> json) {
    return ZoneSubstance(
      coreTakeaway: json['core_takeaway'] != null
          ? CoreTakeaway.fromJson(json['core_takeaway'] as Map<String, dynamic>)
          : null,
      noteBlocks: (json['note_blocks'] as List? ?? [])
          .map((b) => NoteBlock.fromJson(b as Map<String, dynamic>))
          .toList(),
      actionItems: (json['action_items'] as List? ?? [])
          .map((a) => ActionItem.fromJson(a as Map<String, dynamic>))
          .toList(),
      keyPoints: json['key_points'] as String? ?? '',
      toolsResources: (json['tools_resources'] as List? ?? [])
          .map((t) => ToolResource.fromJson(t as Map<String, dynamic>))
          .toList(),
      implementationPlan: (json['implementation_plan'] as List? ?? [])
          .map((s) => ImplementationStep.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CoreTakeaway {
  final String headline;
  final String body;

  const CoreTakeaway({required this.headline, required this.body});

  factory CoreTakeaway.fromJson(Map<String, dynamic> json) {
    return CoreTakeaway(
      headline: json['headline'] as String? ?? '',
      body: json['body'] as String? ?? '',
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

class ToolResource {
  final String name;
  final String type;
  final String description;
  final String? url;

  const ToolResource({
    required this.name,
    required this.type,
    required this.description,
    this.url,
  });

  factory ToolResource.fromJson(Map<String, dynamic> json) {
    return ToolResource(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      description: json['description'] as String? ?? '',
      url: json['url'] as String?,
    );
  }
}

class ImplementationStep {
  final int stepNumber;
  final String title;
  final String description;
  final String? timeEstimate;

  const ImplementationStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    this.timeEstimate,
  });

  factory ImplementationStep.fromJson(Map<String, dynamic> json) {
    return ImplementationStep(
      stepNumber: json['step_number'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      timeEstimate: json['time_estimate'] as String?,
    );
  }
}

// ─── Zone 3 ─────────────────────────────────────────────────────────────────

class ZoneDeep {
  final List<Claim> claims;
  final List<MissingContext> missingContext;
  final RabbitHole? rabbitHole;
  final List<KnowledgeCard> knowledgeCards;
  final List<ReferencedArtifact> referencedArtifacts;
  final TopicMap? topicMap;
  final EffortEstimation? effortEstimation;
  final List<Connection> connections;

  const ZoneDeep({
    required this.claims,
    required this.missingContext,
    this.rabbitHole,
    required this.knowledgeCards,
    required this.referencedArtifacts,
    this.topicMap,
    this.effortEstimation,
    required this.connections,
  });

  factory ZoneDeep.fromJson(Map<String, dynamic> json) {
    return ZoneDeep(
      claims: (json['claims'] as List? ?? [])
          .map((c) => Claim.fromJson(c as Map<String, dynamic>))
          .toList(),
      missingContext: (json['missing_context'] as List? ?? [])
          .map((m) => MissingContext.fromJson(m as Map<String, dynamic>))
          .toList(),
      rabbitHole: json['rabbit_hole'] != null
          ? RabbitHole.fromJson(json['rabbit_hole'] as Map<String, dynamic>)
          : null,
      knowledgeCards: (json['knowledge_cards'] as List? ?? [])
          .map((k) => KnowledgeCard.fromJson(k as Map<String, dynamic>))
          .toList(),
      referencedArtifacts: (json['referenced_artifacts'] as List? ?? [])
          .map((r) => ReferencedArtifact.fromJson(r as Map<String, dynamic>))
          .toList(),
      topicMap: json['topic_map'] != null
          ? TopicMap.fromJson(json['topic_map'] as Map<String, dynamic>)
          : null,
      effortEstimation: json['effort_estimation'] != null
          ? EffortEstimation.fromJson(json['effort_estimation'] as Map<String, dynamic>)
          : null,
      connections: (json['connections'] as List? ?? [])
          .map((c) => Connection.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Claim {
  final String claim;
  final String verifiability; // "fact" | "opinion" | "unverified"
  final String? note;

  const Claim({required this.claim, required this.verifiability, this.note});

  factory Claim.fromJson(Map<String, dynamic> json) {
    return Claim(
      claim: json['claim'] as String? ?? '',
      verifiability: json['verifiability'] as String? ?? 'unverified',
      note: json['note'] as String?,
    );
  }
}

class MissingContext {
  final String category; // "risk" | "limitation" | "trade_off" | "assumption" | etc.
  final String text;

  const MissingContext({required this.category, required this.text});

  factory MissingContext.fromJson(Map<String, dynamic> json) {
    return MissingContext(
      category: json['category'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }
}

class RabbitHole {
  final List<String> followUpQuestions;
  final List<String> knowledgeGaps;
  final List<String> adjacentTopics;
  final List<String> advancedConcepts;

  const RabbitHole({
    required this.followUpQuestions,
    required this.knowledgeGaps,
    required this.adjacentTopics,
    required this.advancedConcepts,
  });

  factory RabbitHole.fromJson(Map<String, dynamic> json) {
    return RabbitHole(
      followUpQuestions: List<String>.from(json['follow_up_questions'] as List? ?? []),
      knowledgeGaps: List<String>.from(json['knowledge_gaps'] as List? ?? []),
      adjacentTopics: List<String>.from(json['adjacent_topics'] as List? ?? []),
      advancedConcepts: List<String>.from(json['advanced_concepts'] as List? ?? []),
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


class TopicMap {
  final String mainTopic;
  final List<String> subtopics;

  const TopicMap({required this.mainTopic, required this.subtopics});

  factory TopicMap.fromJson(Map<String, dynamic> json) {
    return TopicMap(
      mainTopic: json['main_topic'] as String? ?? '',
      subtopics: List<String>.from(json['subtopics'] as List? ?? []),
    );
  }
}

class EffortEstimation {
  final String timeToLearn;
  final String timeToImplement;
  final int difficulty;
  final int effort;
  final String? difficultyRationale;

  const EffortEstimation({
    required this.timeToLearn,
    required this.timeToImplement,
    required this.difficulty,
    required this.effort,
    this.difficultyRationale,
  });

  factory EffortEstimation.fromJson(Map<String, dynamic> json) {
    return EffortEstimation(
      timeToLearn: json['time_to_learn'] as String? ?? '',
      timeToImplement: json['time_to_implement'] as String? ?? '',
      difficulty: json['difficulty'] as int? ?? 0,
      effort: json['effort'] as int? ?? 0,
      difficultyRationale: json['difficulty_rationale'] as String?,
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
