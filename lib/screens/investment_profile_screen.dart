import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fin_wealth/respositories/auth_repository.dart';
import 'package:fin_wealth/config/api_config.dart';
import '../theme/theme.dart';
import '../widgets/common/common.dart';

/// Một câu hỏi trong bài khai phá hồ sơ.
class _Question {
  final String key;
  final String label;
  final bool multi;
  final List<MapEntry<String, String>> options; // value → label
  const _Question(this.key, this.label, this.options, {this.multi = false});
}

/// Một nhóm câu hỏi (≈ 1 bước của wizard web).
class _Group {
  final IconData icon;
  final String title;
  final Color color;
  final List<_Question> questions;
  const _Group(this.icon, this.title, this.color, this.questions);
}

/// Màn "Hồ sơ đầu tư" — khai phá hồ sơ Super Broker.
///
/// Bám đúng bộ trường + nhãn của bài khai phá trên web (`discovery_quiz.html`),
/// dùng deterministic bucket-quiz: prefill đáp án đã lưu rồi map tất định khi lưu
/// (`/api/super-broker/discovery-prefill/` + `/discovery-submit/`).
class InvestmentProfileScreen extends StatefulWidget {
  final bool isOnboarding;
  const InvestmentProfileScreen({super.key, this.isOnboarding = false});

  @override
  State<InvestmentProfileScreen> createState() =>
      _InvestmentProfileScreenState();
}

class _InvestmentProfileScreenState extends State<InvestmentProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  /// Đáp án: single → String, multi (methods) → List<String>.
  final Map<String, dynamic> _answers = {};

  // ── Định nghĩa bài khai phá (khớp discovery_quiz.html của web) ──
  static const _groups = <_Group>[
    _Group(Icons.savings_outlined, 'Tài chính cơ bản', Color(0xFF06B6D4), [
      _Question('capital', 'Quy mô vốn dự kiến?', [
        MapEntry('lt_100', '< 100 triệu'),
        MapEntry('100_500', '100 – 500 triệu'),
        MapEntry('500_2000', '500tr – 2 tỷ'),
        MapEntry('gt_2000', '> 2 tỷ'),
      ]),
      _Question('monthly_savings', 'Dòng tiền tiết kiệm định kỳ hàng tháng?', [
        MapEntry('lt_5', 'Dưới 5 triệu'),
        MapEntry('5_15', '5 – 15 triệu'),
        MapEntry('15_50', '15 – 50 triệu'),
        MapEntry('gt_50', 'Trên 50 triệu'),
      ]),
    ]),
    _Group(Icons.timer_outlined, 'Thời gian & Kinh nghiệm', Color(0xFF7C3AED), [
      _Question('horizon', 'Bạn thường giữ một khoản đầu tư bao lâu?', [
        MapEntry('lt_3m', '< 3 tháng'),
        MapEntry('3_12m', '3 – 12 tháng'),
        MapEntry('1_3y', '1 – 3 năm'),
        MapEntry('gt_3y', '> 3 năm'),
      ]),
      _Question('experience', 'Kinh nghiệm đầu tư của bạn?', [
        MapEntry('new', 'Mới đầu tư'),
        MapEntry('experienced', 'Đã có kinh nghiệm'),
      ]),
    ]),
    _Group(Icons.shield_outlined, 'Dự phòng & Đòn bẩy', Color(0xFF059669), [
      _Question(
          'liquidity_runway', 'Thời gian tích lũy chi tiêu không cần rút vốn?', [
        MapEntry('lt_3', 'Dưới 3 tháng'),
        MapEntry('3_6', '3 – 6 tháng'),
        MapEntry('6_12', '6 – 12 tháng'),
        MapEntry('gt_12', 'Trên 12 tháng'),
      ]),
      _Question('margin_stance', 'Quan điểm dùng margin (đòn bẩy)?', [
        MapEntry('none', 'Không dùng'),
        MapEntry('conservative', 'Hạn chế (<30%)'),
        MapEntry('moderate', 'Linh hoạt (30-60%)'),
        MapEntry('aggressive', 'Đòn bẩy cao (>60%)'),
      ]),
    ]),
    _Group(Icons.security_outlined, 'Chấp nhận rủi ro', Color(0xFFBE123C), [
      _Question('max_loss', 'Mức lỗ tối đa chấp nhận cho cả danh mục?', [
        MapEntry('lt_10', '< 10%'),
        MapEntry('10_20', '10 – 20%'),
        MapEntry('20_30', '20 – 30%'),
        MapEntry('gt_30', '> 30%'),
      ]),
      _Question('risk_tolerance', 'Khẩu vị rủi ro tổng thể?', [
        MapEntry('low', 'Thấp'),
        MapEntry('medium', 'Trung bình'),
        MapEntry('high', 'Cao'),
      ]),
    ]),
    _Group(Icons.auto_graph_outlined, 'Phương pháp đầu tư', Color(0xFFC084FC), [
      _Question('methods', 'Phương pháp ưa thích? (chọn nhiều)', [
        MapEntry('growth', 'Tăng trưởng'),
        MapEntry('value', 'Giá trị'),
        MapEntry('dividend', 'Cổ tức'),
        MapEntry('swing', 'Lướt sóng'),
        MapEntry('accumulation', 'Tích sản'),
      ], multi: true),
    ]),
    _Group(Icons.psychology_outlined, 'Tâm lý & Quyết định', Color(0xFFF59E0B), [
      _Question('fomo', 'Khi thấy một mã đang "nóng", bạn?', [
        MapEntry('none', 'Không bị cuốn'),
        MapEntry('low', 'Hơi để ý'),
        MapEntry('medium', 'Khá dễ mua theo'),
        MapEntry('high', 'Rất dễ FOMO'),
      ]),
      _Question('persistence', 'Khi chiến lược chưa hiệu quả ngay, bạn?', [
        MapEntry('low', 'Hay đổi cách'),
        MapEntry('medium', 'Linh hoạt'),
        MapEntry('high', 'Kiên định chờ'),
      ]),
      _Question('decision_style', 'Bạn ra quyết định chủ yếu dựa vào?', [
        MapEntry('data_driven', 'Logic / dữ liệu'),
        MapEntry('intuitive', 'Trực giác'),
        MapEntry('social_proof', 'Theo trend / bạn bè'),
        MapEntry('mixed', 'Kết hợp'),
      ]),
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _loadPrefill();
  }

  Dio _dio() {
    final auth = context.read<AuthRepository>();
    return Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (auth.accessToken != null)
          'Authorization': 'Bearer ${auth.accessToken}',
      },
    ));
  }

  Future<void> _loadPrefill() async {
    try {
      final resp = await _dio().get('/api/super-broker/discovery-prefill/');
      final data = resp.data;
      if (data is Map) {
        setState(() {
          for (final entry in data.entries) {
            final k = entry.key.toString();
            if (k == 'methods') {
              _answers[k] = (entry.value as List?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  <String>[];
            } else {
              _answers[k] = entry.value?.toString();
            }
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final payload = <String, dynamic>{};
      for (final g in _groups) {
        for (final q in g.questions) {
          final v = _answers[q.key];
          if (q.multi) {
            payload[q.key] = (v as List?) ?? const [];
          } else if (v != null) {
            payload[q.key] = v;
          }
        }
      }

      final resp =
          await _dio().post('/api/super-broker/discovery-submit/', data: payload);
      final body = resp.data as Map? ?? const {};

      if (!mounted) return;
      final reflection = body['reflection']?.toString();
      final confidence = (body['confidence'] as num?)?.round();

      if (reflection != null && reflection.isNotEmpty) {
        await _showReflection(reflection, confidence);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(confidence != null
                ? 'Đã lưu hồ sơ! Độ hoàn thiện: $confidence%'
                : 'Đã lưu hồ sơ đầu tư!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      if (!mounted) return;
      if (widget.isOnboarding) {
        Navigator.of(context).pushNamedAndRemoveUntil('/v2', (route) => false);
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi lưu: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showReflection(String text, int? confidence) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: AppColors.brandPrimaryDark, size: 20),
                  const SizedBox(width: 8),
                  const Text('Hồ sơ của bạn',
                      style: TextStyle(
                          color: AppColors.darkTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (confidence != null)
                    Text('$confidence%',
                        style: const TextStyle(
                            color: AppColors.brandPrimaryDark,
                            fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(text,
                      style: const TextStyle(
                          color: AppColors.darkTextSecondary,
                          fontSize: 14,
                          height: 1.5)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tiếp tục'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: FwAppBar(
        title: widget.isOnboarding ? 'Thiết lập hồ sơ' : 'Hồ Sơ Đầu Tư',
        subtitle: 'Khai phá khẩu vị đầu tư',
        actions: widget.isOnboarding
            ? [
                TextButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil('/v2', (route) => false),
                  child: const Text('Bỏ qua',
                      style: TextStyle(color: Colors.white54, fontSize: 14)),
                ),
              ]
            : const [],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brandPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(context),
                  const SizedBox(height: AppSpacing.xl),
                  for (final g in _groups) ...[
                    _buildGroup(g),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.darkBg,
            border: Border(
                top: BorderSide(
                    color: AppColors.darkBorder.withValues(alpha: 0.5))),
          ),
          child: FwButton(
            label: widget.isOnboarding ? 'Bắt đầu đầu tư' : 'Cập nhật hồ sơ',
            icon: widget.isOnboarding ? Icons.arrow_forward : Icons.save_outlined,
            loading: _isSaving,
            fullWidth: true,
            onPressed: _isSaving ? null : _save,
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandPrimary.withValues(alpha: 0.2),
            AppColors.brandSecondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.2)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars, color: AppColors.brandPrimaryDark, size: 20),
              SizedBox(width: 8),
              Text('Khám phá tiềm năng',
                  style: TextStyle(
                      color: AppColors.brandPrimaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Trả lời nhanh ~12 câu để Mr. Wealth tư vấn đúng khẩu vị đầu tư của bạn.',
            style: TextStyle(
                color: AppColors.darkTextSecondary, height: 1.5, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(_Group g) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: g.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(g.icon, color: g.color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(g.title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < g.questions.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.lg),
            _buildQuestion(g.questions[i], g.color),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestion(_Question q, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(q.label,
            style: const TextStyle(
                color: AppColors.darkTextSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: q.options.map((opt) {
            final selected = q.multi
                ? ((_answers[q.key] as List?)?.contains(opt.key) ?? false)
                : _answers[q.key] == opt.key;
            return _chip(
              label: opt.value,
              selected: selected,
              color: color,
              onTap: () => _toggle(q, opt.key),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _toggle(_Question q, String value) {
    setState(() {
      if (q.multi) {
        final list = List<String>.from((_answers[q.key] as List?) ?? const []);
        if (list.contains(value)) {
          list.remove(value);
        } else {
          list.add(value);
        }
        _answers[q.key] = list;
      } else {
        // Bấm lại lựa chọn đang chọn → bỏ chọn.
        _answers[q.key] = _answers[q.key] == value ? null : value;
      }
    });
  }

  Widget _chip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
              color: selected ? color : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? color : AppColors.darkTextSecondary,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            )),
      ),
    );
  }
}
