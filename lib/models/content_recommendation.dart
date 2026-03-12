class ContentRecommendation {
  final String id;
  final String contentType;
  final String contentId;
  final String title;
  final String description;
  final String? imageUrl;
  final double relevanceScore;
  final List<String> reasons;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  ContentRecommendation({
    required this.id,
    required this.contentType,
    required this.contentId,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.relevanceScore,
    required this.reasons,
    required this.metadata,
    required this.createdAt,
  });

  factory ContentRecommendation.fromJson(Map<String, dynamic> json) {
    return ContentRecommendation(
      id: json['id'] as String? ?? '',
      contentType: json['content_type'] as String? ?? '',
      contentId: json['content_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      relevanceScore: (json['relevance_score'] as num?)?.toDouble() ?? 0.0,
      reasons: (json['reasons'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content_type': contentType,
      'content_id': contentId,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'relevance_score': relevanceScore,
      'reasons': reasons,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
