import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportViewerScreenV2 extends StatefulWidget {
  final String url;
  final String title;
  const ReportViewerScreenV2({super.key, required this.url, required this.title});

  @override
  State<ReportViewerScreenV2> createState() => _ReportViewerScreenV2State();
}

class _ReportViewerScreenV2State extends State<ReportViewerScreenV2> {
  double _progress = 0;

  bool get _supportsWebView {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  void initState() {
    super.initState();
    if (!_supportsWebView) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final uri = Uri.tryParse(widget.url);
        if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.tryParse(widget.url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (!_supportsWebView) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser_outlined),
            tooltip: 'Mở trình duyệt',
            onPressed: _openInBrowser,
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              useHybridComposition: true,
              supportZoom: true,
            ),
            onProgressChanged: (_, progress) {
              setState(() => _progress = progress / 100.0);
            },
          ),
          if (_progress < 1.0)
            LinearProgressIndicator(value: _progress),
        ],
      ),
    );
  }
}
