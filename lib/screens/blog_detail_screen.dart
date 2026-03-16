import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class BlogDetailScreen extends StatefulWidget {
  final String url;
  final String title;

  const BlogDetailScreen({super.key, required this.url, required this.title});

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  double _progress = 0;
  late String _optimizedUrl;
  InAppWebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    // Append ?mode=mobile to force the mobile-optimized template
    final uri = Uri.parse(widget.url);
    final queryParams = Map<String, String>.from(uri.queryParameters);
    queryParams['mode'] = 'mobile';
    _optimizedUrl = uri.replace(queryParameters: queryParams).toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title, 
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => _webViewController?.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser, size: 20),
            onPressed: () => launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication),
            tooltip: 'Mở bằng trình duyệt ngoài',
          ),
        ],
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        bottom: _progress < 1.0 
          ? PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            )
          : null,
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(_optimizedUrl)),
        initialSettings: InAppWebViewSettings(
          useShouldOverrideUrlLoading: true,
          mediaPlaybackRequiresUserGesture: false,
          allowsInlineMediaPlayback: true,
          iframeAllow: "camera; microphone",
          iframeAllowFullscreen: true,
          supportZoom: true,
        ),
        onWebViewCreated: (controller) {
          _webViewController = controller;
        },
        onProgressChanged: (controller, progress) {
          setState(() {
            _progress = progress / 100;
          });
        },
      ),
    );
  }
}
