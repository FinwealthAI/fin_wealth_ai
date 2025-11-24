import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

class AiReportScreen extends StatefulWidget {
  final String ticker;
  final String htmlContent;

  const AiReportScreen({
    Key? key,
    required this.ticker,
    required this.htmlContent,
  }) : super(key: key);

  @override
  State<AiReportScreen> createState() => _AiReportScreenState();
}

class _AiReportScreenState extends State<AiReportScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('📄 Mở báo cáo AI cho ${widget.ticker}');
    debugPrint('📄 HTML length: ${widget.htmlContent.length}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Báo cáo AI - ${widget.ticker}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        elevation: 2,
        shadowColor: theme.colorScheme.shadow.withOpacity(0.3),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface.withOpacity(0.8),
              theme.colorScheme.surfaceContainer.withOpacity(0.9),
            ],
          ),
        ),
        child: _buildHtmlContent(),
      ),
    );
  }

  @override
  void dispose() {
    debugPrint('📄 Đóng báo cáo AI cho ${widget.ticker}');
    super.dispose();
  }

  Widget _buildHtmlContent() {
    final html = widget.htmlContent.trim();

    if (html.isEmpty) {
      return const Center(
        child: Text(
          'Không có nội dung báo cáo.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    debugPrint('🔍 Bắt đầu render HTML, độ dài: ${html.length}');

    try {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800), // ✅ Giới hạn độ rộng như trang AI report
            child: Html(
              data: html,
              onLinkTap: (url, attributes, element) {
                if (url != null) _launchURL(url);
              },
              style: {
                "body": Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  fontFamily: 'Roboto',
                  fontSize: FontSize(15.5),
                  lineHeight: LineHeight.number(1.5),
                  color: Colors.black87,
                  textAlign: TextAlign.justify,
                ),
                "h1": Style(
                  fontSize: FontSize(22),
                  fontWeight: FontWeight.w700,
                  margin: Margins.only(bottom: 12),
                  color: Colors.black87,
                ),
                "h2": Style(
                  fontSize: FontSize(19),
                  fontWeight: FontWeight.w600,
                  margin: Margins.only(top: 16, bottom: 8),
                  color: Colors.black87,
                ),
                "p": Style(
                  margin: Margins.only(bottom: 10),
                  textAlign: TextAlign.justify,
                ),
                "ul": Style(
                  margin: Margins.only(left: 20, bottom: 10),
                  lineHeight: LineHeight.number(1.5),
                ),
                "li": Style(
                  padding: HtmlPaddings.only(bottom: 4),
                ),
              },
              shrinkWrap: true,
              onCssParseError: (css, messages) {
                debugPrint('⚠️ CSS Parse Error: $css');
                debugPrint('⚠️ CSS Messages: $messages');
                return null;
              },
            ),
          ),
        ),
      );
    } catch (e, stack) {
      debugPrint('❌ Lỗi khi render HTML: $e');
      debugPrint(stack.toString());

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '❌ Lỗi khi hiển thị báo cáo:',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            Text('$e'),
            const SizedBox(height: 16),
            const Text(
              '📄 Nội dung thô:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText(html),
          ],
        ),
      );
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể mở liên kết: $url')),
      );
    }
  }
}
