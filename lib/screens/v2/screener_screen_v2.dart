import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../widgets/common/common.dart';

class ScreenerScreenV2 extends StatefulWidget {
  const ScreenerScreenV2({super.key});

  @override
  State<ScreenerScreenV2> createState() => _ScreenerScreenV2State();
}

class _ScreenerScreenV2State extends State<ScreenerScreenV2> {
  final List<_FilterRule> _rules = [
    _FilterRule('P/E', '<', '15'),
    _FilterRule('ROE', '>', '15%'),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: FwAppBar(
        title: 'Lọc cổ phiếu',
        subtitle: '${_rules.length} tiêu chí · 23 kết quả',
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: _openPresets,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: FwCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune,
                          size: 16, color: AppColors.brandPrimaryDark),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Bộ lọc', style: text.titleMedium),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(_rules.clear),
                        child: const Text('Xoá hết'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ..._rules.asMap().entries.map((e) => _buildRule(e.key, e.value)),
                  const SizedBox(height: AppSpacing.sm),
                  FwButton(
                    label: 'Thêm tiêu chí',
                    icon: Icons.add,
                    variant: FwButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: () {
                      setState(() {
                        _rules.add(_FilterRule('Volume', '>', '500K'));
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: FwButton(
                          label: 'Lọc',
                          icon: Icons.search,
                          fullWidth: true,
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      FwButton(
                        label: 'Lưu',
                        icon: Icons.save_outlined,
                        variant: FwButtonVariant.secondary,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          Expanded(child: _buildResultTable()),
        ],
      ),
    );
  }

  Widget _buildRule(int idx, _FilterRule r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _PickerField(label: r.field),
          ),
          const SizedBox(width: 6),
          Expanded(child: _PickerField(label: r.op)),
          const SizedBox(width: 6),
          Expanded(flex: 2, child: _PickerField(label: r.value)),
          IconButton(
            iconSize: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: const Icon(Icons.close, color: AppColors.darkTextMuted),
            onPressed: () => setState(() => _rules.removeAt(idx)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTable() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: 12,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final tickers = ['VNM', 'FPT', 'HPG', 'MSN', 'VIC', 'CTG'];
        final t = tickers[i % tickers.length];
        final price = 50.0 + i * 6.5;
        final pct = (i % 2 == 0 ? 1 : -1) * (0.5 + i * 0.1);
        final color =
            pct >= 0 ? AppColors.successDark : AppColors.dangerDark;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Text(t,
                style: const TextStyle(
                    color: AppColors.brandPrimaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
          title: Text('$t · ${price.toStringAsFixed(2)}'),
          subtitle: Text('P/E ${(8 + i * 0.4).toStringAsFixed(1)} · ROE ${(15 + i).toStringAsFixed(1)}%'),
          trailing: Text(
            '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          onTap: () {},
        );
      },
    );
  }

  void _openPresets() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => const _PresetSheet(),
    );
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  const _PickerField({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.darkTextPrimary, fontSize: 13)),
          ),
          const Icon(Icons.expand_more,
              size: 16, color: AppColors.darkTextMuted),
        ],
      ),
    );
  }
}

class _FilterRule {
  final String field;
  final String op;
  final String value;
  _FilterRule(this.field, this.op, this.value);
}

class _PresetSheet extends StatelessWidget {
  const _PresetSheet();

  @override
  Widget build(BuildContext context) {
    final presets = ['Cổ phiếu giá trị', 'Tăng trưởng cao', 'Cổ tức bền'];
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bộ lọc đã lưu', style: text.titleMedium),
            const SizedBox(height: AppSpacing.md),
            ...presets.map((p) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bookmark,
                      color: AppColors.brandPrimaryDark),
                  title: Text(p),
                  onTap: () => Navigator.pop(context),
                )),
          ],
        ),
      ),
    );
  }
}
