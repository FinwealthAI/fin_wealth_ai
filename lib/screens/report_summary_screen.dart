import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fin_wealth/respositories/stock_reports_repository.dart';
import 'package:fin_wealth/models/stock_reports.dart';

class ReportSummaryScreen extends StatefulWidget {
  const ReportSummaryScreen({
    super.key,
    required this.report,
  });

  final StockReport report; // có sẵn id, ticker, title để hiển thị

  @override
  State<ReportSummaryScreen> createState() => _ReportSummaryScreenState();
}

class _ReportSummaryScreenState extends State<ReportSummaryScreen> {
  Future<String>? _summaryFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final repo = context.read<StockReportsRepository>();
    setState(() => _isLoading = true);

    try {
      String html = '';
      int attempts = 0;
      while (attempts < 3) {
        try {
          html = await repo.getSummaryHtml(widget.report.id);
          break;
        } catch (e) {
          final msg = e.toString();
          if ((msg.contains('502') || msg.contains('Bad Gateway') || msg.contains('chưa có')) && attempts < 2) {
            await Future.delayed(const Duration(seconds: 30));
            attempts++;
            continue;
          } else {
            rethrow;
          }
        }
      }
      setState(() {
        _isLoading = false;
        _summaryFuture = Future.value(html.isNotEmpty ? html : '<p>Không có nội dung tóm tắt</p>');
      });
    } catch (e) {
      setState(() => _isLoading = false);
      final msg = e.toString().contains('chưa sẵn sàng')
          ? 'Tóm tắt AI đang được xử lý. Vui lòng quay lại sau khi hoàn tất.'
          : e.toString();
      _showTimeoutDialog(msg);
    }
  }

  Future<void> _reload() async => _loadSummary();

  void _showTimeoutDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đang xử lý tóm tắt'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) Navigator.of(context).maybePop();
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    return Scaffold(
      appBar: AppBar(
        title: Text('Tóm tắt: ${r.ticker}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Quay lại',
        ),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _summaryFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Lỗi tóm tắt: ${snap.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final html = snap.data ?? '<p>Không có nội dung tóm tắt</p>';
          return Scrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // tiêu đề báo cáo
                  Text(
                    r.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    children: [
                      Text('Mã: ${r.ticker}'),
                      Text('Nguồn: ${r.source}'),
                    ],
                  ),
                  const Divider(height: 24),
                  Html(data: html), // render nội dung tóm tắt
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
