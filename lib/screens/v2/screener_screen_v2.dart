import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../respositories/investment_opportunities_repository.dart';
import '../../theme/theme.dart';
import '../../widgets/common/common.dart';
import 'stock_detail_screen_v2.dart';

// ─── Data model for a single filter rule ─────────────────────────────────────

class _FilterRule {
  String itemCode;
  String itemLabel;
  String comparison; // gt, lt, gte, lte, eq
  String threshold;  // raw user input
  int periods;
  String timeType;   // quy, nam, ngay
  Map<String, dynamic> options;

  _FilterRule({
    required this.itemCode,
    required this.itemLabel,
    this.comparison = 'gt',
    this.threshold = '',
    this.periods = 1,
    this.timeType = 'quy',
    this.options = const {},
  });

  bool get isChoiceType => options['ui_type'] == 'choice';
  bool get hideUiPeriod => options['hide_ui_period'] == true;
  bool get lockTimeType => options['lock_time_type'] == true;
  List<String> get choices =>
      (options['choices'] as List?)?.map((e) => e.toString()).toList() ?? [];

  Map<String, dynamic> toJson() => {
        'item_name': itemCode,
        'comparison': comparison,
        'threshold': double.tryParse(threshold) ?? threshold,
        'periods': periods,
        'time_type': timeType,
      };
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class ScreenerScreenV2 extends StatefulWidget {
  const ScreenerScreenV2({super.key});

  @override
  State<ScreenerScreenV2> createState() => _ScreenerScreenV2State();
}

class _ScreenerScreenV2State extends State<ScreenerScreenV2> {
  late final InvestmentOpportunitiesRepository _repo =
      context.read<InvestmentOpportunitiesRepository>();

  // Fields from backend
  List<Map<String, dynamic>> _groups = [];
  bool _loadingFields = true;

  // Filter state
  String _logic = 'and';
  final List<_FilterRule> _rules = [];

  // Results
  bool _running = false;
  List<String>? _resultTickers;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    try {
      final groups = await _repo.fetchScreenerFields();
      if (mounted) setState(() { _groups = groups; _loadingFields = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingFields = false);
    }
  }

  // Build flat list of all items across groups
  List<Map<String, dynamic>> get _allItems {
    final list = <Map<String, dynamic>>[];
    for (final g in _groups) {
      for (final item in (g['items'] as List? ?? [])) {
        list.add({
          ...Map<String, dynamic>.from(item as Map),
          'group_title': g['title'],
        });
      }
    }
    return list;
  }

  void _addRule() {
    if (_allItems.isEmpty) return;
    final item = _allItems.first;
    final opts = Map<String, dynamic>.from(item['options'] as Map? ?? {});
    final timeType = opts['default_time_type'] as String? ??
        (opts['hide_ui_period'] == true ? 'ngay' : 'quy');
    setState(() {
      _rules.add(_FilterRule(
        itemCode: item['code'] as String,
        itemLabel: item['label'] as String,
        options: opts,
        timeType: timeType,
        comparison: opts['ui_type'] == 'choice' ? 'eq' : 'gt',
        threshold: opts['ui_type'] == 'choice'
            ? ((opts['choices'] as List?)?.first?.toString() ?? '')
            : '',
      ));
    });
  }

  void _removeRule(int idx) => setState(() => _rules.removeAt(idx));

  Future<void> _run() async {
    if (_rules.isEmpty) return;
    setState(() { _running = true; _error = null; _resultTickers = null; });
    final payload = {
      'logic': _logic,
      'rules': _rules.map((r) => r.toJson()).toList(),
    };
    final result = await _repo.runScreener(payload);
    if (!mounted) return;
    if (result.containsKey('error')) {
      setState(() { _running = false; _error = result['error'] as String?; });
    } else {
      final tickers = (result['tickers'] as List?)?.map((e) => e.toString()).toList() ?? [];
      setState(() { _running = false; _resultTickers = tickers; });
    }
  }

  void _openFieldPicker(int ruleIdx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FieldPickerSheet(
        groups: _groups,
        onSelected: (item) {
          final opts = Map<String, dynamic>.from(item['options'] as Map? ?? {});
          final timeType = opts['default_time_type'] as String? ??
              (opts['hide_ui_period'] == true ? 'ngay' : 'quy');
          final isChoice = opts['ui_type'] == 'choice';
          setState(() {
            _rules[ruleIdx] = _FilterRule(
              itemCode: item['code'] as String,
              itemLabel: item['label'] as String,
              options: opts,
              timeType: timeType,
              comparison: isChoice ? 'eq' : 'gt',
              threshold: isChoice
                  ? ((opts['choices'] as List?)?.first?.toString() ?? '')
                  : '',
            );
          });
        },
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        title: const Text(
          'Bộ lọc cổ phiếu',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_resultTickers != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimaryDark.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.brandPrimaryDark.withOpacity(0.5)),
                  ),
                  child: Text(
                    '${_resultTickers!.length} mã',
                    style: TextStyle(
                      color: AppColors.brandPrimaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loadingFields
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLogicSection(),
                        const SizedBox(height: 16),
                        _buildRulesSection(),
                        const SizedBox(height: 12),
                        _buildAddRuleButton(),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          _buildError(),
                        ],
                        if (_resultTickers != null) ...[
                          const SizedBox(height: 20),
                          _buildResults(),
                        ],
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
                _buildRunButton(),
              ],
            ),
    );
  }

  Widget _buildLogicSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Text(
            'Điều kiện lọc',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          _LogicToggle(
            value: _logic,
            onChanged: (v) => setState(() => _logic = v),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesSection() {
    if (_rules.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.darkSurface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Icon(Icons.filter_list_rounded, color: Colors.white30, size: 36),
            const SizedBox(height: 8),
            const Text(
              'Chưa có điều kiện nào',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              'Nhấn "+ Thêm điều kiện" để bắt đầu',
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(_rules.length, (i) {
        return Column(
          children: [
            if (i > 0) _buildLogicDivider(),
            _RuleCard(
              rule: _rules[i],
              onTapField: () => _openFieldPicker(i),
              onRemove: () => _removeRule(i),
              onChanged: () => setState(() {}),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildLogicDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.white12, thickness: 1)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _logic == 'and'
                  ? const Color(0xFF1E3A5F)
                  : const Color(0xFF3A1E2F),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _logic == 'and'
                    ? const Color(0xFF2E5A8F)
                    : const Color(0xFF8F2E5A),
                width: 1,
              ),
            ),
            child: Text(
              _logic == 'and' ? 'VÀ' : 'HOẶC',
              style: TextStyle(
                color: _logic == 'and'
                    ? const Color(0xFF64B5F6)
                    : const Color(0xFFF48FB1),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.white12, thickness: 1)),
        ],
      ),
    );
  }

  Widget _buildAddRuleButton() {
    return GestureDetector(
      onTap: _allItems.isEmpty ? null : _addRule,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.brandPrimaryDark.withOpacity(0.4), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: AppColors.brandPrimaryDark, size: 18),
            const SizedBox(width: 6),
            Text(
              'Thêm điều kiện',
              style: TextStyle(
                color: AppColors.brandPrimaryDark,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunButton() {
    final canRun = _rules.isNotEmpty && !_running;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.darkBg,
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: canRun ? _run : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimaryDark,
              disabledBackgroundColor: AppColors.brandPrimaryDark.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _running
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _rules.isEmpty ? 'Thêm điều kiện trước' : 'Lọc cổ phiếu',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Lỗi: $_error',
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final tickers = _resultTickers!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Kết quả',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brandPrimaryDark.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${tickers.length} mã',
                style: TextStyle(
                  color: AppColors.brandPrimaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (tickers.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Không có cổ phiếu nào phù hợp',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tickers.map((ticker) => _TickerChip(
              ticker: ticker,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => StockDetailScreenV2(ticker: ticker),
              )),
            )).toList(),
          ),
      ],
    );
  }
}

// ─── Logic Toggle ─────────────────────────────────────────────────────────────

class _LogicToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _LogicToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip('VÀ', 'and'),
        const SizedBox(width: 6),
        _chip('HOẶC', 'or'),
      ],
    );
  }

  Widget _chip(String label, String v) {
    final selected = value == v;
    return GestureDetector(
      onTap: () => onChanged(v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? (v == 'and' ? const Color(0xFF1565C0) : const Color(0xFF880E4F))
              : Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white38,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ─── Rule Card ────────────────────────────────────────────────────────────────

class _RuleCard extends StatefulWidget {
  final _FilterRule rule;
  final VoidCallback onTapField;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _RuleCard({
    required this.rule,
    required this.onTapField,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_RuleCard> createState() => _RuleCardState();
}

class _RuleCardState extends State<_RuleCard> {
  late final TextEditingController _thresholdCtrl;

  @override
  void initState() {
    super.initState();
    _thresholdCtrl = TextEditingController(text: widget.rule.threshold);
    _thresholdCtrl.addListener(() {
      widget.rule.threshold = _thresholdCtrl.text;
    });
  }

  @override
  void didUpdateWidget(_RuleCard old) {
    super.didUpdateWidget(old);
    if (old.rule != widget.rule) {
      _thresholdCtrl.text = widget.rule.threshold;
    }
  }

  @override
  void dispose() {
    _thresholdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rule = widget.rule;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field selector row
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: widget.onTapField,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.brandPrimaryDark.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            rule.itemLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down, color: AppColors.brandPrimaryDark, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onRemove,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Comparison + value row
          Row(
            children: [
              // Comparison
              SizedBox(
                width: 110,
                child: _DropdownField<String>(
                  value: rule.isChoiceType ? 'eq' : rule.comparison,
                  items: rule.isChoiceType
                      ? [const DropdownMenuItem(value: 'eq', child: Text('Bằng'))]
                      : const [
                          DropdownMenuItem(value: 'gt', child: Text('> lớn hơn')),
                          DropdownMenuItem(value: 'gte', child: Text('≥ lớn hơn bằng')),
                          DropdownMenuItem(value: 'lt', child: Text('< nhỏ hơn')),
                          DropdownMenuItem(value: 'lte', child: Text('≤ nhỏ hơn bằng')),
                          DropdownMenuItem(value: 'eq', child: Text('= bằng')),
                        ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => rule.comparison = v);
                      widget.onChanged();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Value
              Expanded(
                child: rule.isChoiceType
                    ? _DropdownField<String>(
                        value: rule.choices.contains(rule.threshold)
                            ? rule.threshold
                            : (rule.choices.isNotEmpty ? rule.choices.first : null),
                        items: rule.choices
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => rule.threshold = v);
                            widget.onChanged();
                          }
                        },
                      )
                    : _NumberField(controller: _thresholdCtrl),
              ),
            ],
          ),
          // Period row (only if not hidden)
          if (!rule.hideUiPeriod) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  'Số kỳ:',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: _NumberField(
                    controller: TextEditingController(text: rule.periods.toString())
                      ..addListener(() {}),
                    onChanged: (v) {
                      rule.periods = int.tryParse(v) ?? 1;
                      widget.onChanged();
                    },
                    isInt: true,
                  ),
                ),
                const SizedBox(width: 12),
                if (!rule.lockTimeType) ...[
                  const Text(
                    'Loại:',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    child: _DropdownField<String>(
                      value: rule.timeType,
                      items: const [
                        DropdownMenuItem(value: 'quy', child: Text('Quý')),
                        DropdownMenuItem(value: 'nam', child: Text('Năm')),
                        DropdownMenuItem(value: 'ngay', child: Text('Ngày')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => rule.timeType = v);
                          widget.onChanged();
                        }
                      },
                    ),
                  ),
                ] else
                  Text(
                    _timeTypeLabel(rule.timeType),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _timeTypeLabel(String t) => switch (t) {
        'quy' => 'Quý',
        'nam' => 'Năm',
        'ngay' => 'Ngày',
        _ => t,
      };
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _DropdownField<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _DropdownField({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: const Color(0xFF1C2033),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white38, size: 18),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool isInt;
  const _NumberField({required this.controller, this.onChanged, this.isInt = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: isInt
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: isInt ? '1' : 'Giá trị',
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.brandPrimaryDark.withOpacity(0.5)),
        ),
        isDense: true,
      ),
    );
  }
}

class _TickerChip extends StatelessWidget {
  final String ticker;
  final VoidCallback onTap;
  const _TickerChip({required this.ticker, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.brandPrimaryDark.withOpacity(0.3)),
        ),
        child: Text(
          ticker,
          style: TextStyle(
            color: AppColors.brandPrimaryDark,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ─── Field Picker Bottom Sheet ────────────────────────────────────────────────

class _FieldPickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> groups;
  final ValueChanged<Map<String, dynamic>> onSelected;
  const _FieldPickerSheet({required this.groups, required this.onSelected});

  @override
  State<_FieldPickerSheet> createState() => _FieldPickerSheetState();
}

class _FieldPickerSheetState extends State<_FieldPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = <Map<String, dynamic>>[];
    for (final g in widget.groups) {
      final items = (g['items'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((item) => _search.isEmpty ||
              (item['label'] as String)
                  .toLowerCase()
                  .contains(_search.toLowerCase()))
          .toList();
      if (items.isNotEmpty) {
        filtered.add({'title': g['title'], 'items': items});
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C2033),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Chọn chỉ số',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm chỉ số...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.07),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // List
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: filtered.fold<int>(0, (sum, g) => sum + 1 + (g['items'] as List).length),
                itemBuilder: (_, idx) {
                  int cursor = 0;
                  for (final g in filtered) {
                    if (idx == cursor) {
                      // Group header
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          g['title'] as String,
                          style: TextStyle(
                            color: AppColors.brandPrimaryDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      );
                    }
                    cursor++;
                    final items = g['items'] as List;
                    for (final item in items) {
                      if (idx == cursor) {
                        final m = Map<String, dynamic>.from(item as Map);
                        return ListTile(
                          dense: true,
                          title: Text(
                            m['label'] as String,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onSelected(m);
                          },
                        );
                      }
                      cursor++;
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
