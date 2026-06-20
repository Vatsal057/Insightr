class ActionItem {
  final int id;
  final String text;
  final bool done;
  final String priority; // "now" | "soon" | "someday"
  final String? timeEstimate;
  final int entryId;
  /// Entry title — populated when fetched via /api/todo
  final String? title;
  /// Entry field (category) — populated when fetched via /api/todo
  final String? entryField;

  const ActionItem({
    required this.id,
    required this.text,
    required this.done,
    required this.priority,
    this.timeEstimate,
    required this.entryId,
    this.title,
    this.entryField,
  });

  factory ActionItem.fromJson(Map<String, dynamic> json) {
    final rawDone = json['done'];
    final parsedDone = rawDone is bool
        ? rawDone
        : (rawDone is int ? rawDone == 1 : false);
    return ActionItem(
      id: json['id'] as int,
      text: json['text'] as String? ?? '',
      done: parsedDone,
      priority: json['priority'] as String? ?? 'someday',
      timeEstimate: json['time_estimate'] as String?,
      entryId: json['entry_id'] as int? ?? 0,
      title: json['title'] as String?,
      entryField: json['field'] as String?,
    );
  }

  ActionItem copyWith({bool? done}) {
    return ActionItem(
      id: id, text: text,
      done: done ?? this.done,
      priority: priority,
      timeEstimate: timeEstimate,
      entryId: entryId,
      title: title,
      entryField: entryField,
    );
  }
}
