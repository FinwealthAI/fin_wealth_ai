import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/blog_post.dart';
import '../../respositories/blog_repository.dart';
import '../../theme/theme.dart';
import '../../widgets/common/common.dart';

class BlogDetailScreenV2 extends StatefulWidget {
  final BlogPost post;
  const BlogDetailScreenV2({super.key, required this.post});

  @override
  State<BlogDetailScreenV2> createState() => _BlogDetailScreenV2State();
}

class _BlogDetailScreenV2State extends State<BlogDetailScreenV2> {
  late final BlogRepository _repo = context.read<BlogRepository>();

  BlogPost? _detail;
  bool _loading = true;
  Object? _err;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() { _loading = true; _err = null; });
    try {
      final detail = await _repo.fetchDetail(widget.post.slug);
      if (mounted) setState(() { _detail = detail; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _err = e; _loading = false; });
    }
  }

  Future<void> _openInBrowser() async {
    final webUrl = 'https://finwealth.vn/blog/post/${widget.post.slug}/';
    final uri = Uri.tryParse(webUrl);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.post.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser_outlined, color: Colors.white70),
            tooltip: 'Mở trình duyệt',
            onPressed: _openInBrowser,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_err != null || _detail == null) {
      return Center(
        child: FwEmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Không tải được bài viết',
          message: _err?.toString().replaceFirst('Exception: ', ''),
          action: FwButton(label: 'Thử lại', onPressed: _loadDetail),
        ),
      );
    }

    final post = _detail!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          if (post.thumbnailUrl != null)
            CachedNetworkImage(
              imageUrl: post.thumbnailUrl!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 200,
                color: AppColors.darkSurface,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category chip
                if (post.categoryName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimaryDark.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.brandPrimaryDark.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      post.categoryName!,
                      style: TextStyle(
                          color: AppColors.brandPrimaryDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                const SizedBox(height: 12),

                // Title
                Text(
                  post.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),

                // Meta row: author + date + views
                _MetaRow(post: post),
                const SizedBox(height: 8),
                Divider(color: Colors.white12, height: 24),
              ],
            ),
          ),

          // HTML content
          if (post.content != null && post.content!.isNotEmpty)
            _HtmlContent(html: post.content!),

          // Related posts
          if (post.related.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: Colors.white12, height: 32),
                  const Text(
                    'Bài viết liên quan',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ...post.related.map((r) => _RelatedCard(
                        post: r,
                        onTap: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (_) => BlogDetailScreenV2(post: r)),
                        ),
                      )),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── HTML content renderer ────────────────────────────────────────────────────

class _HtmlContent extends StatelessWidget {
  final String html;
  const _HtmlContent({required this.html});

  @override
  Widget build(BuildContext context) {
    // Sửa lỗi url tương đối từ django-summernote thành url tuyệt đối
    final String parsedHtml = html
        .replaceAll('src="/media/', 'src="https://finwealth.vn/media/')
        .replaceAll("src='/media/", "src='https://finwealth.vn/media/")
        .replaceAll('href="/', 'href="https://finwealth.vn/');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Html(
        data: parsedHtml,
        extensions: [
          ImageExtension(),
        ],
        onLinkTap: (url, _, __) async {
          if (url == null) return;
          final uri = Uri.tryParse(url);
          if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        style: {
          'body': Style(
            color: AppColors.darkTextSecondary,
            fontSize: FontSize(15),
            lineHeight: LineHeight(1.7),
            margin: Margins.zero,
            padding: HtmlPaddings.symmetric(horizontal: 16),
          ),
          'p': Style(
            color: AppColors.darkTextSecondary,
            fontSize: FontSize(15),
            lineHeight: LineHeight(1.7),
            margin: Margins.only(bottom: 14),
          ),
          'h1': Style(
            color: AppColors.darkTextPrimary,
            fontSize: FontSize(22),
            fontWeight: FontWeight.w700,
            margin: Margins.only(top: 20, bottom: 10),
          ),
          'h2': Style(
            color: AppColors.darkTextPrimary,
            fontSize: FontSize(19),
            fontWeight: FontWeight.w700,
            margin: Margins.only(top: 18, bottom: 8),
          ),
          'h3': Style(
            color: AppColors.darkTextPrimary,
            fontSize: FontSize(17),
            fontWeight: FontWeight.w600,
            margin: Margins.only(top: 14, bottom: 6),
          ),
          'h4,h5,h6': Style(
            color: AppColors.darkTextPrimary,
            fontSize: FontSize(15),
            fontWeight: FontWeight.w600,
            margin: Margins.only(top: 12, bottom: 6),
          ),
          'strong,b': Style(
            color: AppColors.darkTextPrimary,
            fontWeight: FontWeight.w700,
          ),
          'a': Style(
            color: AppColors.brandPrimaryDark,
            textDecoration: TextDecoration.underline,
          ),
          'ul,ol': Style(
            margin: Margins.only(bottom: 12, left: 4),
          ),
          'li': Style(
            color: AppColors.darkTextSecondary,
            fontSize: FontSize(15),
            lineHeight: LineHeight(1.6),
            margin: Margins.only(bottom: 4),
          ),
          'blockquote': Style(
            color: AppColors.darkTextMuted,
            fontSize: FontSize(15),
            fontStyle: FontStyle.italic,
            backgroundColor: const Color(0xFF1E2230),
            padding: HtmlPaddings.symmetric(horizontal: 14, vertical: 10),
            margin: Margins.symmetric(vertical: 12),
          ),
          'code,pre': Style(
            color: AppColors.brandPrimaryDark,
            backgroundColor: const Color(0xFF1A1D2E),
            fontFamily: 'monospace',
            fontSize: FontSize(13),
            padding: HtmlPaddings.all(4),
          ),
          'img': Style(
            margin: Margins.symmetric(vertical: 10),
          ),
          'table': Style(
            border: Border.all(color: Colors.white12),
            margin: Margins.symmetric(vertical: 10),
          ),
          'td,th': Style(
            color: AppColors.darkTextSecondary,
            padding: HtmlPaddings.all(8),
            border: Border.all(color: Colors.white10),
          ),
          'th': Style(
            color: AppColors.darkTextPrimary,
            fontWeight: FontWeight.w600,
            backgroundColor: const Color(0xFF1E2230),
          ),
        },
      ),
    );
  }
}

// ─── Meta row ─────────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  final BlogPost post;
  const _MetaRow({required this.post});

  @override
  Widget build(BuildContext context) {
    String? dateStr;
    if (post.publishedAt != null) {
      try {
        final dt = DateTime.parse(post.publishedAt!).toLocal();
        dateStr = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {}
    }

    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        if (post.authorName != null)
          _chip(Icons.person_outline, post.authorName!),
        if (dateStr != null)
          _chip(Icons.calendar_today_outlined, dateStr),
        if (post.viewsCount > 0)
          _chip(Icons.remove_red_eye_outlined, '${post.viewsCount} lượt xem'),
      ],
    );
  }

  Widget _chip(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white38),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      );
}

// ─── Related card ─────────────────────────────────────────────────────────────

class _RelatedCard extends StatelessWidget {
  final BlogPost post;
  final VoidCallback onTap;
  const _RelatedCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            if (post.thumbnailUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                child: CachedNetworkImage(
                  imageUrl: post.thumbnailUrl!,
                  width: 80,
                  height: 70,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 80, height: 70,
                    color: AppColors.darkSurface,
                  ),
                  errorWidget: (_, __, ___) => const SizedBox(width: 80, height: 70),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.4),
                    ),
                    if (post.authorName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        post.authorName!,
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.chevron_right, color: Colors.white24, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
