import 'package:dio/dio.dart';
import 'package:fin_wealth/models/blog_post.dart';
import 'package:fin_wealth/config/api_config.dart';

class BlogCategory {
  final String name;
  final String slug;
  const BlogCategory({required this.name, required this.slug});
}

class BlogRepository {
  final Dio dio;
  BlogRepository(this.dio);

  Future<({List<BlogPost> posts, List<BlogCategory> categories})> fetchPosts({
    String? categorySlug,
    int limit = 30,
    int offset = 0,
  }) async {
    final resp = await dio.get(
      ApiConfig.blogList,
      queryParameters: {
        if (categorySlug != null && categorySlug.isNotEmpty) 'category': categorySlug,
        'limit': limit,
        'offset': offset,
      },
    );
    final data = resp.data as Map<String, dynamic>;
    final posts = (data['posts'] as List<dynamic>)
        .map((e) => BlogPost.fromJson(e as Map<String, dynamic>))
        .toList();
    final categories = (data['categories'] as List<dynamic>)
        .map((e) => BlogCategory(
              name: e['name'] as String,
              slug: e['slug'] as String,
            ))
        .toList();
    return (posts: posts, categories: categories);
  }

  Future<BlogPost> fetchDetail(String slug) async {
    final resp = await dio.get(ApiConfig.blogDetail(slug));
    return BlogPost.fromJson(resp.data as Map<String, dynamic>);
  }
}
