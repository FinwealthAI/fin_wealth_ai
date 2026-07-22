part of '../stock_detail_screen_v2.dart';


// ===== Helpers =====

class _VcStyle {
  final IconData iconData;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final Color pillBg;
  final Color pillText;
  const _VcStyle({
    required this.iconData,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.pillBg,
    required this.pillText,
  });
}

class _ChartPeriodBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ChartPeriodBtn(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.brandPrimaryDark : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color:
                active ? Colors.white : AppColors.darkTextSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Quant Widgets ─────────────────────────────────────────────────────────────

double? _toOptD(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

String _qFmt(dynamic v) => _toOptD(v)?.toStringAsFixed(1) ?? '—';

class _QuantWealthCard extends StatelessWidget {
  final Map wealth;
  const _QuantWealthCard({required this.wealth});

  Color _labelColor(String? label) {
    if (label == null) return AppColors.darkTextMuted;
    if (label.contains('Hội tụ')) return AppColors.goldenAccent;
    if (label.contains('Sóng') || label.contains('Giá trị đang nổi')) return AppColors.successDark;
    if (label.contains('Tiềm năng') || label.contains('Chờ')) return AppColors.warningDark;
    return AppColors.darkTextMuted;
  }

  @override
  Widget build(BuildContext context) {
    final score = _toOptD(wealth['score']);
    final fa = _toOptD(wealth['fa_score']);
    final ta = _toOptD(wealth['ta_score']);
    final label = wealth['strength_label'] as String?;
    final faLabel = wealth['fa_label'] as String?;
    final taLabel = wealth['ta_label'] as String?;
    final date = wealth['date'] as String?;
    final labelColor = _labelColor(label);

    return FwCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome, size: 14, color: AppColors.goldenAccent),
            const SizedBox(width: 6),
            Text('WealthScore', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            if (date != null)
              Text(date, style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 11)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            // Score tổng
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(score != null ? score.toStringAsFixed(1) : '—',
                  style: TextStyle(
                      fontSize: 36, fontWeight: FontWeight.bold,
                      color: score != null && score >= 65 ? AppColors.successDark
                          : score != null && score >= 50 ? AppColors.brandPrimaryDark
                          : score != null && score >= 35 ? AppColors.warningDark
                          : AppColors.dangerDark)),
              const Text('/100', style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12)),
            ]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (label != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: labelColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: labelColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(label,
                        style: TextStyle(color: labelColor, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                const SizedBox(height: 8),
                Row(children: [
                  Flexible(child: _ScorePill('FA', _qFmt(fa), faLabel, AppColors.brandSecondaryDark)),
                  const SizedBox(width: 8),
                  Flexible(child: _ScorePill('TA', _qFmt(ta), taLabel, AppColors.brandPrimaryDark)),
                ]),
              ]),
            ),
          ]),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final String type;
  final String score;
  final String? label;
  final Color color;
  const _ScorePill(this.type, this.score, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(type, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
        Text(score, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        if (label != null)
          Text(label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 9)),
      ]),
    );
  }
}

class _QuantFaCard extends StatelessWidget {
  final Map fa;
  const _QuantFaCard({required this.fa});

  @override
  Widget build(BuildContext context) {
    final pillars = <(String, dynamic, Color)>[
      ('Tăng trưởng', fa['growth'], AppColors.successDark),
      ('Chất lượng', fa['quality'], AppColors.brandPrimaryDark),
      ('Sức khỏe TC', fa['health'], AppColors.brandSecondaryDark),
      ('Định giá', fa['valuation'], AppColors.warningDark),
    ];
    return FwCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            const Icon(Icons.business_outlined, size: 14, color: AppColors.brandSecondaryDark),
            const SizedBox(width: 6),
            Text('FA Score — Cơ bản', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: AppColors.brandSecondaryDark.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(_qFmt(fa['score']),
                  style: const TextStyle(
                      color: AppColors.brandSecondaryDark,
                      fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            if (fa['label'] != null) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(fa['label'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 11)),
              ),
            ],
          ]),
        ),
        const Divider(height: 1, color: AppColors.darkBorder),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            for (final p in pillars) ...[
              _QuantPillarRow(label: p.$1, value: _toOptD(p.$2), color: p.$3),
              const SizedBox(height: 10),
            ],
            if (fa['data_coverage'] != null)
              Row(children: [
                const Icon(Icons.info_outline, size: 12, color: AppColors.darkTextMuted),
                const SizedBox(width: 4),
                Text('Độ phủ dữ liệu: ${fa['data_coverage']}%',
                    style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 11)),
              ]),
          ]),
        ),
      ]),
    );
  }
}

class _QuantTaCard extends StatelessWidget {
  final Map ta;
  const _QuantTaCard({required this.ta});

  @override
  Widget build(BuildContext context) {
    final pillars = <(String, dynamic, Color)>[
      ('Xu hướng', ta['trend'], AppColors.brandPrimaryDark),
      ('Động lực', ta['momentum'], AppColors.successDark),
      ('Khối lượng', ta['volume'], AppColors.brandSecondaryDark),
      ('Vị thế giá', ta['position'], AppColors.warningDark),
    ];
    final divergence = ta['divergence_signal'] as String?;
    final reversalRisk = ta['reversal_risk'] == true;
    final entropy = _toOptD(ta['entropy_multiplier']);

    return FwCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            const Icon(Icons.show_chart, size: 14, color: AppColors.brandPrimaryDark),
            const SizedBox(width: 6),
            Text('TA Score — Kỹ thuật', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: AppColors.brandPrimaryDark.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(_qFmt(ta['score']),
                  style: const TextStyle(
                      color: AppColors.brandPrimaryDark,
                      fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            if (ta['label'] != null) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(ta['label'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 11)),
              ),
            ],
          ]),
        ),
        const Divider(height: 1, color: AppColors.darkBorder),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final p in pillars) ...[
              _QuantPillarRow(label: p.$1, value: _toOptD(p.$2), color: p.$3),
              const SizedBox(height: 10),
            ],
            // Signals
            if (divergence != null || reversalRisk || entropy != null) ...[
              const Divider(height: 16, color: AppColors.darkBorder),
              Wrap(spacing: 8, runSpacing: 6, children: [
                if (divergence != null)
                  _SignalChip(
                    label: 'Phân kỳ: $divergence',
                    color: divergence == 'bullish' ? AppColors.successDark : AppColors.dangerDark,
                    icon: divergence == 'bullish' ? Icons.trending_up : Icons.trending_down,
                  ),
                if (reversalRisk)
                  const _SignalChip(
                    label: 'Rủi ro đảo chiều',
                    color: AppColors.dangerDark,
                    icon: Icons.warning_amber_rounded,
                  ),
                if (entropy != null)
                  _SignalChip(
                    label: 'Entropy ×${entropy.toStringAsFixed(2)}',
                    color: AppColors.darkTextMuted,
                    icon: Icons.blur_on,
                  ),
              ]),
            ],
            if (ta['data_coverage'] != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.info_outline, size: 12, color: AppColors.darkTextMuted),
                const SizedBox(width: 4),
                Text('Độ phủ dữ liệu: ${ta['data_coverage']}%',
                    style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 11)),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }
}

/// Alpha rating (Alpha Zoo) — điểm tổng hợp + điểm theo nhóm chủ đề factor.
/// Nguồn: `factors` trong `/api/quant/scores/<ticker>/`
/// (xem `../finwealth/quant/views.py` → `_get_factor_block`).
class _QuantAlphaCard extends StatelessWidget {
  final Map factors;
  const _QuantAlphaCard({required this.factors});

  Color _ratingColor(double? r) {
    if (r == null) return AppColors.darkTextMuted;
    if (r >= 65) return AppColors.successDark;
    if (r >= 50) return AppColors.goldenAccent;
    if (r >= 35) return AppColors.warningDark;
    return AppColors.dangerDark;
  }

  @override
  Widget build(BuildContext context) {
    final rating = _toOptD(factors['alpha_rating']);
    final date = factors['date'] as String?;
    final themes = (factors['themes'] is List)
        ? List<Map>.from((factors['themes'] as List).whereType<Map>())
        : const <Map>[];
    final color = _ratingColor(rating);

    return FwCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            const Icon(Icons.hub_outlined, size: 14, color: AppColors.goldenAccent),
            const SizedBox(width: 6),
            Text('Alpha Rating', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            if (date != null)
              Text(date, style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 11)),
          ]),
        ),
        const Divider(height: 1, color: AppColors.darkBorder),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(rating != null ? rating.toStringAsFixed(0) : '—',
                  style: TextStyle(
                      fontSize: 34, fontWeight: FontWeight.bold, color: color)),
              const Padding(
                padding: EdgeInsets.only(bottom: 6, left: 2),
                child: Text('/100',
                    style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Điểm tổng hợp từ rổ nhân tố định lượng (alpha).',
                    style: TextStyle(color: AppColors.darkTextMuted, fontSize: 11, height: 1.3)),
              ),
            ]),
            if (themes.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('Theo nhóm nhân tố',
                  style: TextStyle(
                      color: AppColors.darkTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              for (final t in themes) ...[
                _QuantPillarRow(
                  label: (t['name'] as String?) ?? (t['key'] as String? ?? '—'),
                  value: _toOptD(t['score']),
                  color: _ratingColor(_toOptD(t['score'])),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ]),
        ),
      ]),
    );
  }
}

class _QuantPillarRow extends StatelessWidget {
  final String label;
  final double? value;
  final Color color;
  const _QuantPillarRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(
        width: 80,
        child: Text(label, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13)),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value != null ? (value! / 100).clamp(0.0, 1.0) : 0,
            minHeight: 8,
            backgroundColor: AppColors.darkBorder,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 36,
        child: Text(
          value != null ? value!.toStringAsFixed(1) : '—',
          textAlign: TextAlign.right,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    ]);
  }
}

class _SignalChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _SignalChip({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ── Section error / helpers ────────────────────────────────────────────────────

class _SectionError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _SectionError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off,
              color: AppColors.darkTextMuted, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message,
                style:
                    const TextStyle(color: AppColors.darkTextSecondary)),
          ),
          FwMiniButton.soft(
            label: 'Thử lại',
            icon: Icons.refresh,
            onTap: onRetry,
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;
  final String value;
  const _ScoreChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.darkTextMuted,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 3),
          Text(value,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.brandPrimaryDark,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _RangePill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const _RangePill({required this.label, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? AppColors.brandPrimary.withValues(alpha: 0.2)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: active
                  ? AppColors.brandPrimaryDark
                  : AppColors.darkBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: active
                  ? AppColors.brandPrimaryDark
                  : AppColors.darkTextSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool line;
  final bool isDashed;
  const _LegendDot({
    required this.color,
    required this.label,
    this.line = false,
    this.isDashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        isDashed
            ? Row(
                children: [
                  for (int i = 0; i < 3; i++) ...[
                    Container(width: 4, height: 2, color: color),
                    if (i < 2) const SizedBox(width: 2),
                  ],
                ],
              )
            : line
                ? Container(width: 14, height: 2, color: color)
                : Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: AppColors.darkTextSecondary,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _PeriodToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn('Quý', 'quarter'),
          _btn('Năm', 'year'),
        ],
      ),
    );
  }

  Widget _btn(String label, String period) {
    final active = value == period;
    return GestureDetector(
      onTap: () => onChanged(period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.brandPrimaryDark : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.darkTextMuted,
            )),
      ),
    );
  }
}

class _TableHead extends StatelessWidget {
  final String label;
  final bool alignRight;
  const _TableHead(this.label, {this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: AppColors.darkTextMuted,
      ),
    );
  }
}

class _OpportunityRiskCard extends StatelessWidget {
  final double opportunity;
  final double risk;
  final double faScore;
  final double? upside;
  final Map<String, dynamic>? insight;

  const _OpportunityRiskCard({
    required this.opportunity,
    required this.risk,
    required this.faScore,
    this.upside,
    this.insight,
  });

  Color get _oppColor {
    if (opportunity >= 65) return const Color(0xFF22C55E);
    if (opportunity >= 50) return AppColors.brandPrimary;
    return Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final oppInt = opportunity.round();
    final riskInt = risk.round();

    return FwCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  size: 12, color: AppColors.brandPrimaryDark),
              const SizedBox(width: 6),
              Text('Cơ hội & Rủi ro',
                  style: text.titleSmall?.copyWith(fontSize: 12)),
              if (insight != null && insight!['updated_at'] != null && insight!['updated_at'].toString().isNotEmpty) ...[
                const SizedBox(width: 6),
                Text('(${insight!['updated_at']})',
                    style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
              ],
              const Spacer(),
              if (upside == null)
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.2, color: AppColors.darkTextMuted),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$oppInt%',
                    style: text.titleSmall?.copyWith(
                      color: _oppColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text('Cơ hội',
                      style: text.labelSmall?.copyWith(
                          color: AppColors.darkTextMuted, fontSize: 9)),
                ],
              ),
              const Spacer(),
              if (upside != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Icon(
                        upside! >= 0 ? Icons.trending_up : Icons.trending_down,
                        size: 10,
                        color: upside! >= 0
                            ? AppColors.successDark
                            : Colors.redAccent,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Upside: ${upside! >= 0 ? '+' : ''}${upside!.toStringAsFixed(1)}%',
                        style: text.labelSmall?.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: upside! >= 0
                              ? AppColors.successDark
                              : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$riskInt%',
                    style: text.titleSmall?.copyWith(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text('Rủi ro',
                      style: text.labelSmall?.copyWith(
                          color: AppColors.darkTextMuted, fontSize: 9)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 5,
              child: Row(
                children: [
                  Expanded(
                    flex: oppInt,
                    child: Container(color: _oppColor),
                  ),
                  Expanded(
                    flex: riskInt,
                    child: Container(
                        color: Colors.redAccent.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
          ),
          // Tạm ẩn danh sách Cơ hội & Rủi ro (tuân thủ luật bản quyền 1/7)
          // if (insight != null) ...[
          //   const SizedBox(height: AppSpacing.md),
          //   const Divider(height: 1, color: AppColors.darkBorder),
          //   const SizedBox(height: AppSpacing.sm),
          //   _buildInsightList(
          //       insight!['opportunities'] as List<dynamic>?, true),
          //   _buildInsightList(insight!['risks'] as List<dynamic>?, false),
          // ],
        ],
      ),
    );
  }

  // Giữ lại để mở lại danh sách Cơ hội & Rủi ro khi được phép (xem comment trên).
  // ignore: unused_element
  Widget _buildInsightList(List<dynamic>? items, bool isOpp) {
    if (items == null || items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          isOpp ? 'Chưa có dữ liệu từ CTCK' : 'Không phát hiện rủi ro đáng kể',
          style: const TextStyle(
              fontSize: 11,
              color: AppColors.darkTextMuted,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        final text = item.toString();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2.0, right: 6.0),
                child: Icon(
                  isOpp ? Icons.check : Icons.warning_amber_rounded,
                  size: 14,
                  color: isOpp ? AppColors.successDark : Colors.redAccent,
                ),
              ),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.darkTextSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TriangleDotPainter extends FlDotPainter {
  final Color color;
  final double size;

  const _TriangleDotPainter({required this.color, this.size = 7.0});

  @override
  void draw(Canvas canvas, FlSpot spot, Offset center) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx - size * 0.75, center.dy + size * 0.5)
      ..lineTo(center.dx + size * 0.75, center.dy + size * 0.5)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  Size getSize(FlSpot spot) => Size(size * 2, size * 2);

  @override
  Color get mainColor => color;

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) {
    if (a is _TriangleDotPainter && b is _TriangleDotPainter) {
      return _TriangleDotPainter(
        color: Color.lerp(a.color, b.color, t)!,
        size: a.size + (b.size - a.size) * t,
      );
    }
    return b;
  }

  @override
  List<Object?> get props => [color, size];
}
