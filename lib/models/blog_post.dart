class BlogPost {
  final String title;
  final String? summary;
  final String? thumbnailUrl;
  final String detailUrl;
  final String? categoryName;
  final String? categoryIcon;
  final String? authorName;
  final String? authorAvatarUrl;
  final String? publishedAt;
  final int viewsCount;

  BlogPost({
    required this.title,
    this.summary,
    this.thumbnailUrl,
    required this.detailUrl,
    this.categoryName,
    this.categoryIcon,
    this.authorName,
    this.authorAvatarUrl,
    this.publishedAt,
    this.viewsCount = 0,
  });
}
