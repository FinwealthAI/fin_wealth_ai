import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../blocs/stock_reports/stock_reports_bloc.dart';
import '../../blocs/stock_reports/stock_reports_event.dart';
import '../../blocs/stock_reports/stock_reports_state.dart';
import '../../models/stock_reports.dart';
import '../../respositories/stock_reports_repository.dart';
import '../../theme/theme.dart';
import '../../widgets/common/common.dart';
import '../../widgets/dashboard/report_row.dart';
import 'stock_detail_screen_v2.dart';

class ReportsScreenV2 extends StatelessWidget {
  const ReportsScreenV2({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => StockReportsBloc(ctx.read<StockReportsRepository>())
        ..add(StockReportsLoadSources())
        ..add(StockReportsInitialLoad()),
      child: const _ReportsView(),
    );
  }
}

class _ReportsView extends StatefulWidget {
  const _ReportsView();

  @override
  State<_ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<_ReportsView> {
  final TextEditingController _q = TextEditingController();
  final ScrollController _scroll = ScrollController();
  Timer? _debounce;
  String? _activeSourceId;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _q.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 240) {
      context.read<StockReportsBloc>().add(StockReportsLoadMore());
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      context.read<StockReportsBloc>().add(
            StockReportsInitialLoad(
              stock: value.trim().isEmpty ? null : value.trim().toUpperCase(),
              sourceId: _activeSourceId,
            ),
          );
    });
  }

  void _onSourceChanged(StockReportSource src) {
    setState(() => _activeSourceId = src.id == 'all' ? null : src.id);
    context.read<StockReportsBloc>().add(
          StockReportsInitialLoad(
            stock: _q.text.trim().isEmpty ? null : _q.text.trim().toUpperCase(),
            sourceId: _activeSourceId,
          ),
        );
  }

  Future<void> _summarize(BuildContext ctx, StockReport r) async {
    final repo = ctx.read<StockReportsRepository>();
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final html = await repo.getSummaryHtml(r.id);
      if (!mounted) return;
      Navigator.of(ctx).pop();
      showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        backgroundColor: AppColors.darkSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, ctrl) => Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ListView(
              controller: ctrl,
              children: [
                Text('Tóm tắt · ${r.ticker}',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(r.title,
                    style: Theme.of(ctx).textTheme.bodySmall),
                const Divider(height: 24),
                Text(_stripHtml(html),
                    style: Theme.of(ctx).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(ctx).pop();
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  static String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]+>'), '').trim();
  }

  Future<void> _openPdf(StockReport r) async {
    final url = r.fileUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở PDF')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FwAppBar(
        title: 'Báo cáo phân tích',
        subtitle: 'Từ các CTCK hàng đầu',
      ),
      body: BlocBuilder<StockReportsBloc, StockReportsState>(
        builder: (ctx, state) {
          final sources = state.sources;
          final activeIdx = sources.isEmpty
              ? 0
              : sources.indexWhere(
                  (s) => s.id == (_activeSourceId ?? 'all'));
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: TextField(
                  controller: _q,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Tìm theo mã cổ phiếu...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              if (sources.isNotEmpty)
                FwFilterPillBar(
                  items: sources.map((s) => s.name).toList(),
                  activeIndex:
                      activeIdx < 0 ? 0 : activeIdx,
                  onChanged: (i) => _onSourceChanged(sources[i]),
                ),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: _buildBody(state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(StockReportsState state) {
    if (state.status == StockReportsStatus.loading && state.items.isEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, __) =>
            const FwSkeleton(height: 160, radius: AppRadius.lg),
      );
    }
    if (state.status == StockReportsStatus.failure && state.items.isEmpty) {
      return Center(
        child: FwEmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Không tải được báo cáo',
          message: state.error?.replaceFirst('Exception: ', ''),
          action: FwButton(
            label: 'Thử lại',
            onPressed: () => context.read<StockReportsBloc>().add(
                  StockReportsInitialLoad(
                    stock: _q.text.trim().isEmpty
                        ? null
                        : _q.text.trim().toUpperCase(),
                    sourceId: _activeSourceId,
                  ),
                ),
          ),
        ),
      );
    }
    if (state.items.isEmpty) {
      return const Center(
        child: FwEmptyState(
          icon: Icons.inbox_outlined,
          title: 'Chưa có báo cáo phù hợp',
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        context.read<StockReportsBloc>().add(StockReportsRefresh());
      },
      child: ListView.separated(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (ctx, i) {
          if (i >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child:
                  Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
            );
          }
          final r = state.items[i];
          return ReportRow(
            ticker: r.ticker,
            title: r.title,
            date: _fmtDate(r.date),
            source: r.source,
            targetPrice: r.targetPrice?.toDouble(),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => StockDetailScreenV2(ticker: r.ticker))),
            onSummarize: () => _summarize(ctx, r),
            onOpenPdf: r.fileUrl != null ? () => _openPdf(r) : null,
          );
        },
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    if (d.millisecondsSinceEpoch == 0) return '';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm';
  }
}
