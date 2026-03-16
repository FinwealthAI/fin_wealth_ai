import 'package:dio/dio.dart';
import 'package:html/parser.dart' as hp;
import 'package:html/dom.dart';
import 'package:fin_wealth/models/blog_post.dart';
import 'package:fin_wealth/config/api_config.dart';

class BlogRepository {
  final Dio dio;
  BlogRepository(this.dio);

  Future<List<BlogPost>> fetchPosts() async {
    try {
      final response = await dio.get(ApiConfig.blogUrl);
      if (response.statusCode == 200) {
        var document = hp.parse(response.data);
        List<Element> postElements = document.querySelectorAll('.blog-card');
        
        List<BlogPost> posts = [];
        for (var element in postElements) {
          try {
            // Title & Link
            var titleElement = element.querySelector('.blog-card-title a');
            String title = titleElement?.text.trim() ?? 'Không có tiêu đề';
            String relativeUrl = titleElement?.attributes['href'] ?? '';
            String detailUrl = relativeUrl.startsWith('http') 
                ? relativeUrl 
                : '${ApiConfig.websiteUrl}$relativeUrl';

            // Summary
            String summary = element.querySelector('.card-text')?.text.trim() ?? '';

            // Thumbnail
            String? thumbnailUrl;
            var imgElement = element.querySelector('.blog-card-img-wrapper img');
            if (imgElement != null) {
              String src = imgElement.attributes['src'] ?? '';
              thumbnailUrl = src.startsWith('http') ? src : '${ApiConfig.websiteUrl}$src';
            }

            // Category
            var catElement = element.querySelector('.blog-card-category');
            String categoryName = catElement?.text.trim() ?? '';
            String categoryIcon = catElement?.querySelector('i')?.attributes['class'] ?? '';

            // Author & Views
            var metaDivision = element.querySelector('.blog-card-meta');
            
            // Author Name
            String authorName = metaDivision?.querySelector('.d-flex.align-items-center .text-muted.small')?.text.trim() ?? 'FinWealth';
            
            // Author Avatar
            String? authorAvatarUrl;
            var avatarImg = metaDivision?.querySelector('img.blog-author-avatar-sm');
            if (avatarImg != null) {
              String avatarSrc = avatarImg.attributes['src'] ?? '';
              authorAvatarUrl = avatarSrc.startsWith('http') ? avatarSrc : '${ApiConfig.websiteUrl}$avatarSrc';
            }

            // Views Count
            int viewsCount = 0;
            var viewsElement = metaDivision?.querySelector('.text-muted.small:last-child');
            if (viewsElement != null) {
              String viewsText = viewsElement.text.trim();
              viewsCount = int.tryParse(viewsText.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            }

            // Published date is not explicitly in the new compact layout yet, but could be added
            // For now, keep it empty or use viewsCount as placeholder if needed
            String publishedAt = "";

            posts.add(BlogPost(
              title: title,
              summary: summary,
              thumbnailUrl: thumbnailUrl,
              detailUrl: detailUrl,
              categoryName: categoryName,
              categoryIcon: categoryIcon,
              authorName: authorName,
              authorAvatarUrl: authorAvatarUrl,
              publishedAt: publishedAt,
              viewsCount: viewsCount,
            ));
          } catch (e) {
            print('Error parsing blog post: $e');
          }
        }
        return posts;
      }
    } catch (e) {
      print('Failed to fetch blog posts: $e');
    }
    return [];
  }
}
