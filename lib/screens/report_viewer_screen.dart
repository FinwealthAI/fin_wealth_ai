import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

// Conditional import for web-specific code
import 'web_stub.dart' if (dart.library.html) 'web_impl.dart';

class ReportViewerScreen extends StatefulWidget {
  final String url;
  final String? title;

  const ReportViewerScreen({super.key, required this.url, this.title});

  @override
  State<ReportViewerScreen> createState() => _ReportViewerScreenState();
}

class _ReportViewerScreenState extends State<ReportViewerScreen> {
  bool _isPdfError = false;
  String? _iframeId;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _iframeId = 'pdf-viewer-iframe-${widget.url.hashCode}';
      registerIframeViewFactory(_iframeId!, widget.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Report URL: ${widget.url}'); // Debug URL
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Xem báo cáo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Mở trên trình duyệt',
            onPressed: () => _openBrowser(widget.url),
          ),
        ],
      ),
      body: kIsWeb ? _buildWebViewer() : _buildMobileViewer(),
    );
  }

  Widget _buildWebViewer() {
    if (_iframeId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    // On web, use iframe to display PDF
    return HtmlElementView(viewType: _iframeId!);
  }

  Widget _buildMobileViewer() {
    // On mobile/desktop, use Syncfusion PDF Viewer
    if (_isPdfError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Không thể tải báo cáo trực tiếp.'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Mở trên trình duyệt'),
              onPressed: () => _openBrowser(widget.url),
            ),
          ],
        ),
      );
    }

    return SfPdfViewer.network(
      widget.url,
      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
        print('PDF Load Error: ${details.error}');
        print('Description: ${details.description}');
        setState(() {
          _isPdfError = true;
        });
      },
    );
  }

  Future<void> _openBrowser(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}