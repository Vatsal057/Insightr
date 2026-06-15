class Concept {
  final int id;
  final String conceptType;
  final String name;
  final String summary;

  const Concept({
    required this.id,
    required this.conceptType,
    required this.name,
    required this.summary,
  });

  factory Concept.fromJson(Map<String, dynamic> json) {
    return Concept(
      id: json['id'] as int? ?? 0,
      conceptType: json['concept_type'] as String? ?? '',
      name: json['name'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
    );
  }
}
