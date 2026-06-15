import 'action_item.dart';

/// Summary card returned by GET /api/feed
class FeedCard {
  final int id;
  final String title;
  final String hook;
  final String field;
  final String contentType;
  final List<String> tags;
  final String createdAt;
  final ActionItem? topAction;
  final int actionItemCount;
  final int nowActionCount;
  final int implementationStepCount;
  final int toolCount;
  final EffortPill? effortPill;

  const FeedCard({
    required this.id,
    required this.title,
    required this.hook,
    required this.field,
    required this.contentType,
    required this.tags,
    required this.createdAt,
    this.topAction,
    required this.actionItemCount,
    required this.nowActionCount,
    required this.implementationStepCount,
    required this.toolCount,
    this.effortPill,
  });

  factory FeedCard.fromJson(Map<String, dynamic> json) {
    return FeedCard(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      hook: json['hook'] as String? ?? '',
      field: json['field'] as String? ?? '',
      contentType: json['content_type'] as String? ?? '',
      tags: List<String>.from(json['tags'] as List? ?? []),
      createdAt: json['created_at'] as String? ?? '',
      topAction: json['top_action'] != null
          ? ActionItem.fromJson(json['top_action'] as Map<String, dynamic>)
          : null,
      actionItemCount: json['action_item_count'] as int? ?? 0,
      nowActionCount: json['now_action_count'] as int? ?? 0,
      implementationStepCount: json['implementation_step_count'] as int? ?? 0,
      toolCount: json['tool_count'] as int? ?? 0,
      effortPill: json['effort_pill'] != null
          ? EffortPill.fromJson(json['effort_pill'] as Map<String, dynamic>)
          : null,
    );
  }
}

class EffortPill {
  final String label;
  final int difficulty;
  final int effort;
  final String timeToImplement;
  final String timeToLearn;

  const EffortPill({
    required this.label,
    required this.difficulty,
    required this.effort,
    required this.timeToImplement,
    required this.timeToLearn,
  });

  factory EffortPill.fromJson(Map<String, dynamic> json) {
    return EffortPill(
      label: json['label'] as String? ?? '',
      difficulty: json['difficulty'] as int? ?? 0,
      effort: json['effort'] as int? ?? 0,
      timeToImplement: json['time_to_implement'] as String? ?? '',
      timeToLearn: json['time_to_learn'] as String? ?? '',
    );
  }
}
