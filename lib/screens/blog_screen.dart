import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fin_wealth/config/api_config.dart';

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  double _progress = 0;
  InAppWebViewController? _webViewController;
  late String _blogUrl;

  @override
  void initState() {
    super.initState();
    // Use the dynamic blogUrl from ApiConfig and append mode=mobile
    final uri = Uri.parse(ApiConfig.blogUrl);
    final queryParams = Map<String, String>.from(uri.queryParameters);
    queryParams['mode'] = 'mobile';
    _blogUrl = uri.replace(queryParameters: queryParams).toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog đầu tư', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _webViewController?.reload(),
            tooltip: 'Tải lại',
          ),
        ],
        bottom: _progress < 1.0 
          ? PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary.withOpacity(0.5)),
              ),
            )
          : null,
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(_blogUrl)),
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
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          var uri = navigationAction.request.url;
          if (uri != null && uri.toString() != _blogUrl) {
            // Check if it's a detail link or just another page in the blog
            // If it's a blog detail link, we can just let it load in this same view
            // to keep the experience unified, or we could launch the detail screen.
            // For simplicity and better performance, we'll stay in this WebView.
            return NavigationActionPolicy.ALLOW;
          }
          return NavigationActionPolicy.ALLOW;
        },
      ),
    );
  }
}
