class Collection {
  final String name;
  final int entryCount;

  const Collection({required this.name, required this.entryCount});

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      name: json['name'] as String? ?? '',
      entryCount: json['entry_count'] as int? ?? 0,
    );
  }
}
