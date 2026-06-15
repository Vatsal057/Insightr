class ActionItem {
  final int id;
  final String text;
  final bool done;
  final String priority; // "now" | "soon" | "someday"
  final String? timeEstimate;
  final int entryId;
  final String? title; // Included when fetched from /api/todo

  const ActionItem({
    required this.id,
    required this.text,
    required this.done,
    required this.priority,
    this.timeEstimate,
    required this.entryId,
    this.title,
  });

  factory ActionItem.fromJson(Map<String, dynamic> json) {
    return ActionItem(
      id: json['id'] as int,
      text: json['text'] as String? ?? '',
      done: json['done'] as bool? ?? false,
      priority: json['priority'] as String? ?? 'someday',
      timeEstimate: json['time_estimate'] as String?,
      entryId: json['entry_id'] as int? ?? 0,
      title: json['title'] as String?,
    );
  }

  ActionItem copyWith({bool? done}) {
    return ActionItem(
      id: id,
      text: text,
      done: done ?? this.done,
      priority: priority,
      timeEstimate: timeEstimate,
      entryId: entryId,
      title: title,
    );
  }
}
