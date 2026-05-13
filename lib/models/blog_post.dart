class BlogPost {
  final int? id;
  final String title;
  final String slug;
  final String? summary;
  final String? content; // HTML content (for detail screen)
  final String? thumbnailUrl;
  final String? categoryName;
  final String? categorySlug;
  final String? authorName;
  final String? publishedAt;
  final int viewsCount;
  final List<BlogPost> related;

  BlogPost({
    this.id,
    required this.title,
    required this.slug,
    this.summary,
    this.content,
    this.thumbnailUrl,
    this.categoryName,
    this.categorySlug,
    this.authorName,
    this.publishedAt,
    this.viewsCount = 0,
    this.related = const [],
  });

  factory BlogPost.fromJson(Map<String, dynamic> j) => BlogPost(
        id: j['id'] as int?,
        title: (j['title'] as String?) ?? '',
        slug: (j['slug'] as String?) ?? '',
        summary: j['summary'] as String?,
        content: j['content'] as String?,
        thumbnailUrl: j['thumbnail'] as String?,
        categoryName: j['category'] as String?,
        categorySlug: j['category_slug'] as String?,
        authorName: j['author'] as String?,
        publishedAt: j['published_at'] as String?,
        viewsCount: (j['views_count'] as int?) ?? 0,
        related: (j['related'] as List<dynamic>?)
                ?.where((e) => e is Map<String, dynamic>)
                .map((e) => BlogPost.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  // Legacy detailUrl kept for backward compat (unused in new flow)
  String get detailUrl => slug;
}
