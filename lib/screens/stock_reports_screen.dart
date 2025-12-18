import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';

import 'package:fin_wealth/screens/report_summary_screen.dart';
import 'package:fin_wealth/models/stock_reports.dart';
import 'package:fin_wealth/respositories/stock_reports_repository.dart';
import 'package:fin_wealth/blocs/stock_reports/stock_reports_bloc.dart';
import 'package:fin_wealth/blocs/stock_reports/stock_reports_event.dart';
import 'package:fin_wealth/blocs/stock_reports/stock_reports_state.dart';
import 'package:fin_wealth/screens/search_stock_screen.dart';
import 'package:fin_wealth/screens/report_viewer_screen.dart';
import 'package:url_launcher/url_launcher.dart';


class StockReportsScreen extends StatefulWidget {
  const StockReportsScreen({super.key});
  @override
  State<StockReportsScreen> createState() => _StockReportsScreenState();
}

class _StockReportsScreenState extends State<StockReportsScreen> {
  late final StockReportsBloc _bloc;
  final _searchCtrl = TextEditingController();
  String? _selectedSource = 'all';
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    // LẤY repo từ Provider, KHÔNG new Dio()
    final repo = context.read<StockReportsRepository>();
    _bloc = StockReportsBloc(repo)
      ..add(StockReportsLoadSources())
      ..add(StockReportsInitialLoad());

    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 120) {
        _bloc.add(StockReportsLoadMore());
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _bloc.close();
    super.dispose();
  }

  void _doSearch() {
    _bloc.add(StockReportsInitialLoad(
      stock: _searchCtrl.text.trim().toUpperCase(),
      sourceId: _selectedSource,
    ));
  }

  Future<void> _showSummaryDialog(BuildContext context, StockReport report) async {
    final repo = context.read<StockReportsRepository>();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 600,
            height: 520,
            child: FutureBuilder<String>(
              future: repo.getSummaryHtml(report.id), // 🔹 gọi API tóm tắt
              builder: (ctx, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Lỗi tóm tắt: ${snap.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Đóng'),
                        ),
                      ],
                    ),
                  );
                }
                final html = snap.data ?? '<p>Không có nội dung tóm tắt</p>';
                return Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Tóm tắt: ${report.ticker}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close),
                            tooltip: 'Đóng',
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Html(data: html), // render HTML
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocProvider.value(
      value: _bloc,
      child: Container(
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
        child: Column(
          children: [
            // thanh filter
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  // Ô tìm kiếm mã cổ phiếu
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchCtrl,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _doSearch(),
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'CP',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Dropdown nguồn
                  Expanded(
                    flex: 2,
                    child: BlocBuilder<StockReportsBloc, StockReportsState>(
                      builder: (context, state) {
                        final sources = state.sources;
                        return DropdownButtonFormField<String>(
                          value: sources.isNotEmpty ? (_selectedSource ?? 'all') : null,
                          isDense: true,
                          isExpanded: true,
                          dropdownColor: theme.colorScheme.surfaceContainer,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.8),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                            ),
                          ),
                          items: sources
                              .map((s) => DropdownMenuItem<String>(
                                    value: s.id,
                                    child: Text(
                                      s.name, 
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedSource = v),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Nút tìm kiếm
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: FilledButton(
                        onPressed: _doSearch,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Đi', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // danh sách
            Expanded(
              child: BlocBuilder<StockReportsBloc, StockReportsState>(
                builder: (context, state) {
                  if (state.status == StockReportsStatus.loading ||
                      state.status == StockReportsStatus.initial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.status == StockReportsStatus.failure) {
                    return Center(child: Text('Lỗi: ${state.error}'));
                  }
                  final items = state.items;
                  if (items.isEmpty) {
                    return const Center(child: Text('Không có báo cáo'));
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      _bloc.add(StockReportsRefresh());
                      // chờ nhẹ cho dễ nhìn (hoặc dùng Completer trong Bloc)
                      await Future.delayed(const Duration(milliseconds: 300));
                    },
                    child: ListView.separated(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: items.length +
                          (state.status == StockReportsStatus.loadingMore ? 1 : 0),
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        if (i >= items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child:
                                Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }
                        final r = items[i];
                        return _ReportRow(
                          report: r,
                          onSummary: () => _showSummaryDialog(context, r), // 🔹 gọi tóm tắt
                        );
                      },
                    ),
                  );
                },
              ),
            ),
        ],
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.report, required this.onSummary});
  final StockReport report;
  final VoidCallback onSummary;

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtMoney(num v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i;
      buf.write(s[i]);
      if (idx > 1 && idx % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SearchStockScreen(ticker: report.ticker),
                  settings: const RouteSettings(name: 'search_stock'),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                report.ticker,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(children: [
                      const Icon(Icons.event, size: 16),
                      const SizedBox(width: 4),
                      Text(_fmtDate(report.date))
                    ]),
                    if (report.targetPrice != null)
                      Row(children: [
                        const Icon(Icons.attach_money, size: 16),
                        const SizedBox(width: 4),
                        Text(_fmtMoney(report.targetPrice!))
                      ]),
                    Row(children: [
                      const Icon(Icons.apartment, size: 16),
                      const SizedBox(width: 4),
                      Text(report.source)
                    ]),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReportSummaryScreen(report: report),
                      settings: const RouteSettings(name: 'report_summary'),
                    ),
                  );
                },
                child: const Text('Tóm tắt'),
              ),
              if (report.fileUrl?.isNotEmpty == true) ...[
                const SizedBox(height: 6),
                OutlinedButton(
                  onPressed: () async {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReportViewerScreen(
                          url: report.fileUrl!,
                          title: report.title,
                        ),
                      ),
                    );
                  },
                  child: const Text('Xem file'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
