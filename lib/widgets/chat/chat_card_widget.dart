import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/chat_models.dart';
import '../../screens/v2/stock_detail_screen_v2.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Render THẺ DỮ LIỆU inline (sự kiện SSE `type: card`) — bản mobile của
/// `chat_cards.js` trên web. Số liệu lấy từ backend (đã tính sẵn), render thuần.
///
/// 8 variant: stock | action | market | comparison | opportunity | portfolio
///            | strategy | chart.
class ChatCardWidget extends StatelessWidget {
  final ChatCard card;
  const ChatCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final d = card.data;
    switch (card.variant) {
      case 'stock':
        return _StockCard(ticker: card.ticker ?? '', d: d);
      case 'action':
        return _ActionCard(ticker: card.ticker ?? '', d: d);
      case 'market':
        return _MarketCard(d: d);
      case 'comparison':
        return _ListCard(
          title: 'So sánh',
          items: _items(d),
          builder: (it) => _MiniRow(it: it),
        );
      case 'opportunity':
        return _ListCard(
          title: 'Cơ hội nổi bật hôm nay',
          items: _items(d),
          builder: (it) => _OpportunityRow(it: it),
        );
      case 'portfolio':
        return _PortfolioCard(d: d);
      case 'strategy':
        return _StrategyCard(d: d);
      case 'chart':
        return _ChartCard(d: d);
      default:
        return const SizedBox.shrink();
    }
  }

  static List<Map<String, dynamic>> _items(Map<String, dynamic> d) {
    final raw = d['items'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

num? _num(dynamic v) => v is num ? v : (v == null ? null : num.tryParse('$v'));

String _fmtVnd(num v) {
  final s = v.round().abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '${v < 0 ? '-' : ''}$buf';
}

/// Bảng màu cho các tên màu Tailwind dùng trong card.
Color _namedColor(String? name) {
  switch (name) {
    case 'emerald':
      return const Color(0xFF34D399);
    case 'rose':
      return const Color(0xFFFB7185);
    case 'amber':
      return const Color(0xFFFBBF24);
    case 'orange':
      return const Color(0xFFFB923C);
    case 'sky':
      return const Color(0xFF38BDF8);
    case 'blue':
      return const Color(0xFF60A5FA);
    case 'purple':
      return const Color(0xFFC084FC);
    case 'slate':
    default:
      return AppColors.darkTextSecondary;
  }
}

Color _tierColor(String? tier) {
  if (tier == 'manh') return const Color(0xFFC084FC);
  if (tier == 'chu_y') return const Color(0xFF34D399);
  return AppColors.darkTextMuted;
}

void _openTicker(BuildContext context, String? ticker) {
  final t = (ticker ?? '').toUpperCase();
  if (t.isEmpty) return;
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => StockDetailScreenV2(ticker: t)),
  );
}

const _cardMargin = EdgeInsets.only(bottom: AppSpacing.sm);

BoxDecoration _cardDeco({Color? border, Color? bg}) => BoxDecoration(
      color: bg ?? Colors.white.withValues(alpha: 0.02),
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: border ?? AppColors.darkBorder),
    );

/// Nhãn nhỏ kiểu "uppercase tracking" cho tiêu đề card.
Widget _cardTitle(String text) => Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: AppColors.darkTextMuted,
      ),
    );

/// Chip chiến lược (strategies = [{name, icon, color}]).
List<Widget> _stratChips(dynamic list) {
  if (list is! List) return const [];
  return list.whereType<Map>().take(5).map((raw) {
    final s = Map<String, dynamic>.from(raw);
    final c = _namedColor(s['color']?.toString());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        s['name']?.toString() ?? '',
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: c),
      ),
    );
  }).toList();
}

Widget _changeChip(num? chg) {
  if (chg == null) return const SizedBox.shrink();
  final up = chg >= 0;
  return Text(
    '${up ? '▲' : '▼'} ${chg.abs().toStringAsFixed(2)}%',
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: up ? const Color(0xFF34D399) : const Color(0xFFFB7185),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// STOCK
// ─────────────────────────────────────────────────────────────────────────────

class _StockCard extends StatelessWidget {
  final String ticker;
  final Map<String, dynamic> d;
  const _StockCard({required this.ticker, required this.d});

  @override
  Widget build(BuildContext context) {
    final tk = ticker.toUpperCase();
    final chg = _num(d['change_1d_pct']);
    final close = _num(d['close']);
    final score = d['score'];
    final faLabel = d['fa_label']?.toString();
    final taLabel = d['ta_label']?.toString();
    final upside = _num(d['upside_pct']);
    final hasBuy = d['has_buy_signal'] == true;
    final chips = _stratChips(d['strategies']);

    return Container(
      margin: _cardMargin,
      decoration: _cardDeco(),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => _openTicker(context, tk),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(tk,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                  const SizedBox(width: AppSpacing.sm),
                  if (close != null)
                    Text(_fmtVnd(close),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkTextSecondary)),
                  const SizedBox(width: AppSpacing.xs),
                  _changeChip(chg),
                  const Spacer(),
                  if (score != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34D399).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                            color: const Color(0xFF34D399)
                                .withValues(alpha: 0.2)),
                      ),
                      child: Text('$score',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF34D399))),
                    ),
                ],
              ),
              if (faLabel != null || taLabel != null || upside != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (faLabel != null)
                      _kvLabel('FA:', faLabel, _tierColor(d['fa_tier']?.toString())),
                    if (taLabel != null)
                      _kvLabel('TA:', taLabel, _tierColor(d['ta_tier']?.toString())),
                    if (upside != null)
                      Text(
                        'Upside ${upside >= 0 ? '+' : ''}$upside%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: upside >= 0
                              ? const Color(0xFF34D399)
                              : const Color(0xFFFB7185),
                        ),
                      ),
                  ],
                ),
              ],
              if (chips.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(spacing: 4, runSpacing: 4, children: chips),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  if (hasBuy)
                    const Text('▲ Có tín hiệu mua',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF34D399))),
                  const Spacer(),
                  const Text('Chi tiết →',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.darkTextMuted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kvLabel(String k, String v, Color color) => RichText(
        text: TextSpan(children: [
          TextSpan(
              text: '$k ',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.darkTextMuted)),
          TextSpan(
              text: v,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION (DECISION)
// ─────────────────────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final String ticker;
  final Map<String, dynamic> d;
  const _ActionCard({required this.ticker, required this.d});

  @override
  Widget build(BuildContext context) {
    final tk = ticker.toUpperCase();
    final color = _namedColor(d['color']?.toString());
    final label = d['label']?.toString() ?? '';
    final fit = _num(d['fit_pct']);
    final trigger = d['trigger']?.toString();
    final stopHint = d['stop_hint']?.toString();
    final reasons = (d['reasons'] is List)
        ? (d['reasons'] as List).map((e) => e.toString()).toList()
        : <String>[];

    return Container(
      margin: _cardMargin,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDeco(
        border: color.withValues(alpha: 0.3),
        bg: color.withValues(alpha: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tk,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: color)),
              ),
              const Spacer(),
              if (fit != null)
                Text('Mức phù hợp $fit%',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.darkTextMuted)),
            ],
          ),
          if (trigger != null && trigger.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(trigger,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.darkTextSecondary)),
          ],
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...reasons.map((r) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('• $r',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.darkTextSecondary)),
                )),
          ],
          if (stopHint != null && stopHint.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(stopHint,
                style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppColors.darkTextMuted)),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARKET
// ─────────────────────────────────────────────────────────────────────────────

class _MarketCard extends StatelessWidget {
  final Map<String, dynamic> d;
  const _MarketCard({required this.d});

  static const _regLbl = {
    'bullish': 'Tăng trưởng',
    'sideways': 'Đi ngang',
    'bearish': 'Suy yếu',
    'volatile': 'Biến động',
  };

  Color _scoreColor(num s) => s >= 65
      ? const Color(0xFF10B981)
      : s >= 50
          ? const Color(0xFF3B82F6)
          : s >= 35
              ? const Color(0xFFF59E0B)
              : const Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final score = _num(d['final_score']) ?? 50;
    final col = _scoreColor(score);
    final reg = _regLbl[d['tech_regime']?.toString()] ??
        (d['tech_regime']?.toString() ?? '—');

    return Container(
      margin: _cardMargin,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Góc nhìn thị trường'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: col.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: col.withValues(alpha: 0.27)),
                ),
                child: Text(reg,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: col)),
              ),
              Text(score.toStringAsFixed(1),
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: col)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (score / 100).clamp(0, 1).toDouble(),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(col),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                  child: _comp('⚙️ Kỹ thuật', _num(d['tech_score']),
                      const Color(0xFF3B82F6))),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: _comp('📊 Độ rộng', _num(d['breadth_score']),
                      const Color(0xFF10B981))),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                  child: _comp('💰 Định giá', _num(d['val_score']),
                      const Color(0xFFF97316))),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: _comp('🤖 Mr. Wealth', _num(d['ai_score']),
                      const Color(0xFFA855F7))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _comp(String label, num? val, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkTextMuted)),
          const SizedBox(height: 4),
          Text(val != null ? val.toStringAsFixed(1) : '--',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ((val ?? 0) / 100).clamp(0, 1).toDouble(),
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LIST CARD (comparison / opportunity)
// ─────────────────────────────────────────────────────────────────────────────

class _ListCard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final Widget Function(Map<String, dynamic>) builder;
  const _ListCard(
      {required this.title, required this.items, required this.builder});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: _cardMargin,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(title),
          const SizedBox(height: AppSpacing.sm),
          ...items.map(builder),
        ],
      ),
    );
  }
}

class _MiniRow extends StatelessWidget {
  final Map<String, dynamic> it;
  const _MiniRow({required this.it});

  @override
  Widget build(BuildContext context) {
    final tk = (it['ticker']?.toString() ?? '').toUpperCase();
    final chg = _num(it['change_1d_pct']);
    final close = _num(it['close']);
    final score = it['score'];
    final up = _num(it['upside_pct']);
    return _RowShell(
      ticker: tk,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (close != null)
            Text(_fmtVnd(close),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.darkTextSecondary)),
          if (chg != null) ...[
            const SizedBox(width: 6),
            Text('${chg >= 0 ? '▲' : '▼'}${chg.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: chg >= 0
                        ? const Color(0xFF34D399)
                        : const Color(0xFFFB7185))),
          ],
          if (score != null) ...[
            const SizedBox(width: 6),
            Text('$score',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF34D399))),
          ],
          if (up != null) ...[
            const SizedBox(width: 6),
            Text('Up ${up >= 0 ? '+' : ''}$up%',
                style: TextStyle(
                    fontSize: 10,
                    color: up >= 0
                        ? const Color(0xFF34D399)
                        : const Color(0xFFFB7185))),
          ],
        ],
      ),
    );
  }
}

class _OpportunityRow extends StatelessWidget {
  final Map<String, dynamic> it;
  const _OpportunityRow({required this.it});

  @override
  Widget build(BuildContext context) {
    final tk = (it['ticker']?.toString() ?? '').toUpperCase();
    final score = it['score'];
    final label = it['label']?.toString();
    final chips = _stratChips(it['strategies']);
    return _RowShell(
      ticker: tk,
      leadingExtra: chips.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Wrap(spacing: 4, children: chips),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null)
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.darkTextMuted)),
          if (score != null) ...[
            const SizedBox(width: 6),
            Text('$score',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF34D399))),
          ],
        ],
      ),
    );
  }
}

/// Khung hàng chung cho list card — ticker bên trái (tap mở chi tiết), nội dung phải.
class _RowShell extends StatelessWidget {
  final String ticker;
  final Widget child;
  final Widget? leadingExtra;
  const _RowShell(
      {required this.ticker, required this.child, this.leadingExtra});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () => _openTicker(context, ticker),
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Text(ticker,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
            if (leadingExtra != null) Flexible(child: leadingExtra!),
            const Spacer(),
            child,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PORTFOLIO
// ─────────────────────────────────────────────────────────────────────────────

class _PortfolioCard extends StatelessWidget {
  final Map<String, dynamic> d;
  const _PortfolioCard({required this.d});

  @override
  Widget build(BuildContext context) {
    final mrStatus = d['mr_status']?.toString();
    final mrColor = {
          'safe': const Color(0xFF34D399),
          'warning': const Color(0xFFFBBF24),
          'critical': const Color(0xFFFB7185),
        }[mrStatus] ??
        AppColors.darkTextSecondary;
    final mrRatio = _num(d['mr_ratio']);
    final num = d['num_holdings'] ?? 0;
    final items = ChatCardWidget._items(d);

    return Container(
      margin: _cardMargin,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _cardTitle('Danh mục ($num mã)'),
              if (mrRatio != null)
                Text('MR ${mrRatio.round()}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: mrColor)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...items.map((it) {
            final tk = (it['ticker']?.toString() ?? '').toUpperCase();
            final pnl = _num(it['pnl_pct']);
            final drift = _num(it['drift_pct']);
            return _RowShell(
              ticker: tk,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (drift != null && drift.abs() >= 5)
                    Text('lệch ${drift >= 0 ? '+' : ''}$drift%',
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFFFBBF24))),
                  const SizedBox(width: 6),
                  Text(
                    pnl != null ? '${pnl >= 0 ? '+' : ''}$pnl%' : '—',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: pnl == null
                          ? AppColors.darkTextMuted
                          : (pnl >= 0
                              ? const Color(0xFF34D399)
                              : const Color(0xFFFB7185)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STRATEGY (promo)
// ─────────────────────────────────────────────────────────────────────────────

class _StrategyCard extends StatelessWidget {
  final Map<String, dynamic> d;
  const _StrategyCard({required this.d});

  static const _riskMap = {
    'LOW': ['Rủi ro thấp', Color(0xFF34D399)],
    'HIGH': ['Rủi ro cao', Color(0xFFFB7185)],
    'MEDIUM': ['Rủi ro TB', Color(0xFFFBBF24)],
  };
  static const _perMap = {
    'SHORT': 'Ngắn hạn',
    'LONG': 'Dài hạn',
    'MEDIUM': 'Trung hạn',
  };

  @override
  Widget build(BuildContext context) {
    final color = _namedColor(d['color']?.toString());
    final title = d['title']?.toString() ?? '';
    final desc = d['description']?.toString();
    final risk = _riskMap[d['risk_level']?.toString()] ?? _riskMap['MEDIUM']!;
    final period = _perMap[d['investment_period']?.toString()];
    final target = d['target_investor']?.toString();
    final owner = d['owner_name']?.toString() ?? '';
    final followers = d['followers_count'] ?? 0;
    final isOwned = d['is_owned'] == true;
    final isFollowing = d['is_following'] == true;

    final badges = <Widget>[
      _badge(risk[0] as String, risk[1] as Color),
      if (period != null) _badge(period, const Color(0xFF38BDF8)),
      if (target != null && target.isNotEmpty)
        _badge(target, AppColors.darkTextSecondary),
    ];

    return Container(
      margin: _cardMargin,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(Icons.insights, size: 15, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ),
              const Icon(Icons.people_outline,
                  size: 13, color: AppColors.darkTextMuted),
              const SizedBox(width: 2),
              Text('$followers',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.darkTextMuted)),
            ],
          ),
          if (desc != null && desc.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(desc,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.darkTextSecondary)),
          ],
          if (badges.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(spacing: 4, runSpacing: 4, children: badges),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text('bởi $owner',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.darkTextMuted)),
              ),
              _followPill(isOwned, isFollowing),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      );

  Widget _followPill(bool owned, bool following) {
    if (owned) {
      return _badge('Của bạn', AppColors.darkTextMuted);
    }
    final c = following ? const Color(0xFF34D399) : const Color(0xFFC084FC);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(following ? Icons.check_circle : Icons.add_circle_outline,
              size: 12, color: c),
          const SizedBox(width: 4),
          Text(following ? 'Đang theo dõi' : 'Theo dõi',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: c)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHART (sparkline)
// ─────────────────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final Map<String, dynamic> d;
  const _ChartCard({required this.d});

  @override
  Widget build(BuildContext context) {
    final rawPts = (d['points'] is List) ? d['points'] as List : const [];
    final pts = rawPts
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((p) => p['value'] != null)
        .toList();
    if (pts.length < 2) return const SizedBox.shrink();

    final col = _namedColor(d['color']?.toString());
    final chg = _num(d['change_pct']);
    final last = _num(d['last']);
    final unit = d['unit']?.toString() ?? '';
    final vals = pts.map((p) => (_num(p['value']) ?? 0).toDouble()).toList();

    return Container(
      margin: _cardMargin,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(d['title']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkTextSecondary)),
              ),
              if (chg != null)
                Text('${chg >= 0 ? '▲' : '▼'} ${chg.abs().toStringAsFixed(2)}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: chg >= 0
                            ? const Color(0xFF34D399)
                            : const Color(0xFFFB7185))),
            ],
          ),
          if (d['subtitle'] != null) ...[
            const SizedBox(height: 2),
            Text(d['subtitle'].toString(),
                style: const TextStyle(
                    fontSize: 10, color: AppColors.darkTextMuted)),
          ],
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 56,
            width: double.infinity,
            child: CustomPaint(painter: _SparklinePainter(vals, col)),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(pts.first['label']?.toString() ?? '',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.darkTextMuted)),
              Text(
                last != null
                    ? '${_fmtVnd(last)}${unit.isNotEmpty ? ' $unit' : ''}'
                    : '--',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkTextSecondary),
              ),
              Text(pts.last['label']?.toString() ?? '',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.darkTextMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  _SparklinePainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    const pad = 5.0;
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final span = (maxV - minV) == 0 ? 1.0 : (maxV - minV);
    final n = values.length;
    double x(int i) => pad + i * (size.width - 2 * pad) / (n - 1);
    double y(double v) =>
        size.height - pad - (v - minV) / span * (size.height - 2 * pad);

    final path = Path()..moveTo(x(0), y(values[0]));
    for (var i = 1; i < n; i++) {
      path.lineTo(x(i), y(values[i]));
    }

    final area = Path.from(path)
      ..lineTo(x(n - 1), size.height - pad)
      ..lineTo(x(0), size.height - pad)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
    canvas.drawCircle(
        Offset(x(n - 1), y(values[n - 1])), 2.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.color != color;
}
