import 'package:flutter_html/flutter_html.dart';
import 'dart:math' as math;
import 'package:fin_wealth/widgets/strategy_card.dart';
import 'package:fin_wealth/widgets/strategy_card_list.dart';
import 'package:fin_wealth/widgets/strategy_promo_card.dart';
import 'package:fin_wealth/screens/search_stock_screen.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fin_wealth/models/investment_opportunities.dart';
import 'package:fin_wealth/respositories/investment_opportunities_repository.dart';
import 'package:fin_wealth/screens/report_viewer_screen.dart';
import 'package:fin_wealth/screens/chat_screen.dart';
import 'package:fin_wealth/respositories/auth_repository.dart';
import 'package:fin_wealth/respositories/watchlist_repository.dart';
import 'package:fin_wealth/screens/report_summary_screen.dart';
import 'package:fin_wealth/models/stock_reports.dart';
import 'package:fin_wealth/respositories/search_stock_repository.dart';
import 'package:fin_wealth/screens/ai_report_screen.dart';

class MainScreen extends StatefulWidget {
  final Function(String ticker)? onAskAI;

  const MainScreen({super.key, this.onAskAI});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Future<DailySummaryData?>? _summaryFuture;
  int _selectedTabIndex = 0; // 0: Following, 1: Community
  List<StrategyCardData> _followingStrategies = [];
  List<StrategyCardData> _communityStrategies = [];
  bool _isLoadingStrategies = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final repo = context.read<InvestmentOpportunitiesRepository>();
    setState(() {
      _summaryFuture = repo.fetchDailySummary();
      _isLoadingStrategies = true;
    });

    try {
      final results = await Future.wait([
        repo.fetchStrategies(tab: 'following'),
        repo.fetchStrategies(tab: 'community'),
      ]);
      
      if (mounted) {
        setState(() {
          _followingStrategies = results[0];
          _communityStrategies = results[1];
          _isLoadingStrategies = false;
        });
      }
    } catch (e) {
      print('Error fetching strategies: $e');
      if (mounted) setState(() => _isLoadingStrategies = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        elevation: 2,
        shadowColor: theme.colorScheme.shadow.withOpacity(0.3),
        centerTitle: false,
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
        child: SafeArea(
          child: StreamBuilder<DailySummaryData?>(
            stream: _summaryFuture?.asStream(), // converting Future to Stream for StreamBuilder or just use FutureBuilder
            builder: (context, summarySnap) {
              if (summarySnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (summarySnap.hasError) {
                return Center(child: Text('Lỗi tải tóm tắt: ${summarySnap.error}'));
              }

              final summaryData = summarySnap.data;
              final date = summaryData?.date ?? '';
              final aiSummary = summaryData?.aiGeneratedSummary ?? '';
              final newsHighlights = summarySnap.data?.newsHighlights ?? [];
              final reportHighlights = summarySnap.data?.reportHighlights ?? [];
              
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- AI Summary Card ---
                    if (aiSummary.isNotEmpty)
                      _AISummaryCard(
                        date: date,
                        summary: aiSummary,
                        newsHighlights: newsHighlights,
                      ),
                    if (aiSummary.isNotEmpty) const SizedBox(height: 16),

                    // --- Report Highlights ---
                    if (reportHighlights.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'Báo cáo đáng chú ý',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Mỗi báo cáo 1 hàng để không bị cắt chữ
                      Column(
                        children: reportHighlights.take(2).map((report) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ReportHighlightCard(
                              report: report,
                              width: double.infinity,
                              onAskAI: widget.onAskAI,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // --- Strategy Tabs & List ---
                    const SizedBox(height: 24),
                    _buildStrategyTabs(theme),
                    const SizedBox(height: 16),
                    _buildSelectedStrategyList(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  Widget _buildStrategyTabs(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTabItem(theme, 'Đã theo dõi', 0),
          _buildTabItem(theme, 'Cộng đồng', 1),
        ],
      ),
    );
  }

  Widget _buildTabItem(ThemeData theme, String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(21),
            boxShadow: isSelected 
                ? [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedStrategyList() {
    if (_isLoadingStrategies) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(),
      ));
    }

    final list = _selectedTabIndex == 0 ? _followingStrategies : _communityStrategies;

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.folder_open, size: 48, color: Colors.grey.withOpacity(0.5)),
              const SizedBox(height: 8),
              Text(
                'Chưa có dữ liệu',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: list.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 16),
      itemBuilder: (ctx, i) {
        if (_selectedTabIndex == 1) { // Community / Promo Tab
           return StrategyPromoCard(
             data: list[i],
             width: double.infinity,
           );
        }
        return StrategyCard(
          data: list[i],
          width: double.infinity,
        );
      },
    );
  }
}


/// ------------------------------
/// Section wrapper card
/// ------------------------------
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 8),
            blurRadius: 18,
          )
        ],
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}



/// ------------------------------
/// AI Summary Card with gradient border
/// ------------------------------
class _AISummaryCard extends StatefulWidget {
  const _AISummaryCard({
    required this.date,
    required this.summary,
    required this.newsHighlights,
  });

  final String date;
  final String summary;
  final List<dynamic> newsHighlights;

  @override
  State<_AISummaryCard> createState() => _AISummaryCardState();
}

class _AISummaryCardState extends State<_AISummaryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark 
            ? const Color(0xFF1E1E2C) 
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Name & Badge
          Row(
            children: [
              Text(
                'M.A.I',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Finwealth AI',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF6366F1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Title - gọn hơn
          Text(
            'Wealth insights ${widget.date}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Content
          ClipRect(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              alignment: Alignment.topCenter,
              heightFactor: _isExpanded ? 1.0 : 0.25,
              child: Html(
                data: widget.summary,
                style: {
                  "body": Style(
                    fontSize: FontSize(14),
                    color: theme.colorScheme.onSurface.withOpacity(0.85),
                    lineHeight: LineHeight(1.5),
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                  ),
                  "strong": Style(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6366F1),
                  ),
                  "ul": Style(
                    margin: Margins.only(left: 0),
                    padding: HtmlPaddings.only(left: 16),
                  ),
                  "ol": Style(
                    margin: Margins.only(left: 0),
                    padding: HtmlPaddings.only(left: 16),
                  ),
                  "li": Style(
                    margin: Margins.only(bottom: 4),
                  ),
                },
              ),
            ),
          ),
          
          // Read More Button
          if (!_isExpanded)
            Container(
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (theme.brightness == Brightness.dark ? const Color(0xFF1E1E2C) : const Color(0xFFF8F9FA)).withOpacity(0.1),
                    (theme.brightness == Brightness.dark ? const Color(0xFF1E1E2C) : const Color(0xFFF8F9FA)),
                  ],
                  stops: const [0.0, 0.8],
                ),
              ),
            ),
          
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _isExpanded ? 'Thu gọn' : '... Đọc tiếp',
                style: const TextStyle(
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------------------
/// Report Highlight Card
/// ------------------------------
class _ReportHighlightCard extends StatelessWidget {
  const _ReportHighlightCard({
    required this.report,
    this.width,
    this.onAskAI,
  });

  final ReportHighlight report;
  final double? width;
  final Function(String ticker)? onAskAI;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Map ReportHighlight to StockReport for Summary Screen navigation
    final stockReport = StockReport(
      id: report.id ?? 0,
      ticker: report.tags.isNotEmpty ? report.tags.first : '',
      title: report.title,
      date: DateTime.tryParse(report.date) ?? DateTime.now(),
      source: report.source,
      fileUrl: report.filePresigned,
    );

    return Container(
      width: width ?? 320, // Use dynamic width or fallback
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Ticker Badge + Source
          Row(
            children: [
               if (report.tags.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      report.tags.first,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
               Expanded(
                 child: Text(
                   report.title,
                   style: theme.textTheme.titleSmall?.copyWith(
                     fontWeight: FontWeight.bold,
                     fontSize: 15,
                   ),
                   maxLines: 2,
                   overflow: TextOverflow.ellipsis,
                 ),
               ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Info Row
          Wrap(
            spacing: 12,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.business, size: 14, color: theme.colorScheme.secondary),
                  const SizedBox(width: 4),
                  Text(
                    report.source,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.secondary),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(report.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Summary Content
          Text(
            report.summary ?? 'Đang cập nhật nội dung tóm tắt...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Footer Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. File Status / View File
              InkWell(
                onTap: report.filePresigned != null
                    ? () {
                        // Navigate to report viewer
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReportViewerScreen(
                              url: report.filePresigned!,
                              title: report.title,
                            ),
                          ),
                        );
                      }
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.description_outlined, 
                        size: 16, 
                        color: report.filePresigned != null ? theme.colorScheme.primary : Colors.grey
                      ),
                      const SizedBox(width: 4),
                      Text(
                        report.filePresigned != null ? 'Xem file' : 'Không có file',
                        style: TextStyle(
                           fontSize: 12,
                           color: report.filePresigned != null ? theme.colorScheme.primary : Colors.grey,
                           fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Summary
              InkWell(
                onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportSummaryScreen(report: stockReport),
                      ),
                    );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Tóm tắt',
                        style: TextStyle(
                           fontSize: 12,
                           color: theme.colorScheme.primary,
                           fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Ask Mr Wealth
              Material(
                color: const Color(0xFFFCE7F3), // Pink 50
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () {
                     final tickers = report.tags.join(' ');
                     if (onAskAI != null) {
                       onAskAI!(tickers);
                     } else {
                       // Fallback
                        final authRepo = context.read<AuthRepository>();
                        final userData = {
                          'username': authRepo.username ?? 'user',
                        };
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              userData: userData,
                              initialMessage: tickers.isNotEmpty ? tickers : null,
                            ),
                          ),
                        );
                     }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                         const CircleAvatar(
                           radius: 9,
                           backgroundImage: AssetImage('assets/images/mr_wealth_avatar.png'),
                           backgroundColor: Colors.transparent,
                         ),
                         const SizedBox(width: 4),
                         const Text(
                           'Chat',
                           style: TextStyle(
                             fontSize: 11,
                             color: Color(0xFFBE185D), // Pink 700
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return date;
    }
  }
}

/// ------------------------------
/// Meta Chip (for source, date, etc.)
/// ------------------------------
class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.onSurface.withOpacity(0.6);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: chipColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: chipColor),
        ),
      ],
    );
  }
}

/// ------------------------------
/// Ticker Chip
/// ------------------------------
class _TickerChip extends StatelessWidget {
  const _TickerChip({required this.ticker});

  final String ticker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchStockScreen(ticker: ticker),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
        ),
        child: Text(
          ticker,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
