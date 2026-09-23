import 'dart:async';

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

/// Chiến lược được backend bật sẵn sau khảo sát (chỉ để HIỂN THỊ).
///
/// Luật chọn nằm trọn ở server (`stock_screener/strategy_recommender.py`) — mobile
/// không tự chấm điểm lại, tránh 2 nguồn sự thật.
class _StartStrategy {
  final String name;
  final String risk;
  final String period;
  const _StartStrategy(this.name, this.risk, this.period);

  static _StartStrategy? fromJson(dynamic json) {
    if (json is! Map) return null;
    final name = json['name']?.toString().trim() ?? '';
    if (name.isEmpty) return null;
    return _StartStrategy(
      name,
      json['risk_level']?.toString() ?? '',
      json['investment_period']?.toString() ?? '',
    );
  }
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

  /// Summary-first (khớp UX web mới): mở màn Hồ sơ → hiện TÓM TẮT read-only trước;
  /// nút "Chỉnh sửa" mới vào form khai phá. Onboarding thì vào thẳng form.
  bool _showSummary = false;
  Map<String, dynamic>? _summary;

  /// Đáp án: single → String, multi (methods) → `List<String>`.
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
    _init();
  }

  Future<void> _init() async {
    await _loadPrefill();
    // Non-onboarding: tải tóm tắt; có nội dung → hiện màn TÓM TẮT trước.
    final hasSummary = widget.isOnboarding ? false : await _loadSummary();
    if (mounted) {
      setState(() {
        _showSummary = hasSummary;
        _isLoading = false;
      });
    }
  }

  /// Tải tóm tắt hồ sơ (API mới của web). Trả true nếu có nội dung để hiển thị.
  Future<bool> _loadSummary() async {
    try {
      final resp = await _dio().get('/api/super-broker/profile-summary/');
      final data = resp.data;
      if (data is Map) {
        _summary = Map<String, dynamic>.from(data);
        final sections = (data['sections'] as List?) ?? const [];
        final traits = (data['traits'] as List?) ?? const [];
        return sections.isNotEmpty || traits.isNotEmpty;
      }
    } catch (_) {}
    return false;
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
      }
    } catch (_) {}
    // _isLoading do _init quản lý sau khi tải xong cả prefill + summary.
  }

  /// Chốt onboarding phía backend: đặt giao diện mặc định + bật chiến lược gợi ý.
  ///
  /// FAIL-OPEN: lỗi mạng ở đây chỉ mất phần "chiến lược khởi đầu", user vẫn vào
  /// được app — khảo sát đã lưu xong ở lời gọi trước đó.
  /// `dio` truyền sẵn khi màn sắp bị hủy (nút "Bỏ qua") — `_dio()` đọc
  /// `context.read`, gọi sau khi điều hướng là dùng context đã chết.
  Future<List<_StartStrategy>> _completeOnboarding({Dio? dio}) async {
    try {
      final resp =
          await (dio ?? _dio()).post('/api/onboarding/complete/', data: const {});
      final body = resp.data as Map? ?? const {};
      final raw = (body['strategies'] as List?) ?? const [];
      return raw
          .map(_StartStrategy.fromJson)
          .whereType<_StartStrategy>()
          .toList();
    } catch (_) {
      return const [];
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

      // Onboarding: chốt đăng ký ngay sau khảo sát → backend tự bật chiến lược
      // hợp khẩu vị (không bắt người mới tự chọn). Lỗi ở đây KHÔNG chặn luồng.
      final started =
          widget.isOnboarding ? await _completeOnboarding() : const <_StartStrategy>[];

      if (!mounted) return;
      final reflection = body['reflection'];
      final confidence = (body['confidence'] as num?)?.round();

      if (reflection is Map || started.isNotEmpty) {
        await _showReflection(
          reflection is Map ? Map<String, dynamic>.from(reflection) : const {},
          confidence,
          started,
        );
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
        // Quay lại màn TÓM TẮT với dữ liệu vừa cập nhật (khớp UX web: sửa xong → xem lại).
        await _loadSummary();
        if (mounted) setState(() => _showSummary = true);
      }
    } on DioException catch (e) {
      if (mounted) {
        String msg = 'Không thể kết nối đến máy chủ, vui lòng thử lại.';
        if (e.response?.statusCode == 401) {
          msg = 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.';
        } else if (e.response?.data is Map) {
          msg = e.response?.data['message'] ?? e.response?.data['detail'] ?? msg;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Có lỗi xảy ra, vui lòng thử lại.'),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Màn kết quả khảo sát — khớp bản web: chân dung đầu tư + chiến lược đã bật.
  ///
  /// `reflection` là OBJECT (`archetype`/`strengths`/`blind_spots`/
  /// `suitable_methods`), không phải chuỗi.
  Future<void> _showReflection(
    Map<String, dynamic> reflection,
    int? confidence,
    List<_StartStrategy> started,
  ) {
    final archetype = reflection['archetype'];
    final arch = archetype is Map ? archetype : const {};
    final strengths = _stringList(reflection['strengths']);
    final blindSpots = _stringList(reflection['blind_spots']);
    final methods = _stringList(reflection['suitable_methods']);

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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (arch.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _archChip('Rủi ro', arch['risk']),
                            _archChip('Phương pháp', arch['methods']),
                            _archChip('Chu kỳ', arch['horizon']),
                          ].whereType<Widget>().toList(),
                        ),
                      ...?_bulletSection('💪 Điểm mạnh', strengths),
                      ...?_bulletSection(
                          '🪞 Điểm cần lưu ý', blindSpots,
                          color: AppColors.warningDark),
                      ...?_bulletSection('🧭 Phương pháp phù hợp', methods),
                      ...?_startedSection(started),
                    ],
                  ),
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

  static List<String> _stringList(dynamic v) => v is List
      ? v.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList()
      : const <String>[];

  /// Chip một chiều của chân dung; thiếu giá trị → null (không render ô rỗng).
  Widget? _archChip(String label, dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == 'Chưa xác định' || text == 'Chưa chọn') {
      return null;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
      ),
      child: Text('$label: $text',
          style: const TextStyle(
              color: AppColors.darkTextPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    );
  }

  List<Widget>? _bulletSection(String title, List<String> items,
      {Color color = AppColors.darkTextSecondary}) {
    if (items.isEmpty) return null;
    return [
      const SizedBox(height: AppSpacing.lg),
      Text(title,
          style: const TextStyle(
              color: AppColors.darkTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: TextStyle(color: color, fontSize: 13)),
              Expanded(
                child: Text(item,
                    style:
                        TextStyle(color: color, fontSize: 13, height: 1.5)),
              ),
            ],
          ),
        ),
    ];
  }

  /// "Đã bật N chiến lược cho bạn" — chỉ có ở luồng đăng ký.
  List<Widget>? _startedSection(List<_StartStrategy> started) {
    if (started.isEmpty) return null;
    return [
      const SizedBox(height: AppSpacing.lg),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.success, size: 16),
                const SizedBox(width: 6),
                Text('Đã bật ${started.length} chiến lược cho bạn',
                    style: const TextStyle(
                        color: AppColors.darkTextPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            for (final s in started)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  [s.name, s.risk, s.period]
                      .where((e) => e.isNotEmpty)
                      .join(' · '),
                  style: const TextStyle(
                      color: AppColors.darkTextSecondary,
                      fontSize: 12,
                      height: 1.4),
                ),
              ),
            const SizedBox(height: 4),
            const Text(
              'Hợp với khẩu vị bạn vừa khai. Có thể đổi bất kỳ lúc nào ở mục Chiến lược.',
              style: TextStyle(
                  color: AppColors.darkTextMuted, fontSize: 10, height: 1.4),
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Summary-first: đã có hồ sơ + không onboarding → hiện màn TÓM TẮT read-only.
    if (!_isLoading && _showSummary) return _buildSummaryScaffold(context);
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: FwAppBar(
        title: widget.isOnboarding ? 'Thiết lập hồ sơ' : 'Hồ Sơ Đầu Tư',
        subtitle: 'Khai phá khẩu vị đầu tư',
        actions: widget.isOnboarding
            ? [
                TextButton(
                  onPressed: () {
                    // Bỏ qua khảo sát vẫn được bật bộ chiến lược mặc định —
                    // giống web: bỏ trống mọi câu vẫn nhận 2 chiến lược an toàn.
                    // Không chờ mạng để nút "Bỏ qua" phản hồi tức thì.
                    unawaited(_completeOnboarding(dio: _dio()));
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/v2', (route) => false);
                  },
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

  // ── Màn TÓM TẮT hồ sơ (read-only) — khớp popup profile_summary.html của web ──
  Widget _buildSummaryScaffold(BuildContext context) {
    final s = _summary ?? const {};
    final sections = (s['sections'] as List?) ?? const [];
    final traits = (s['traits'] as List?) ?? const [];
    final confidence = (s['confidence'] as num?)?.round();
    final isStale = s['is_stale'] == true;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: FwAppBar(
        title: 'Hồ Sơ Đầu Tư',
        subtitle: confidence != null
            ? 'Độ hoàn thiện: $confidence%'
            : 'Khẩu vị & đặc tính đầu tư',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isStale) ...[
              _staleBanner(),
              const SizedBox(height: AppSpacing.lg),
            ],
            for (final sec in sections) ...[
              _summarySection(sec as Map),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (traits.isNotEmpty) _traitsCard(traits),
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
            label: 'Chỉnh sửa hồ sơ',
            icon: Icons.edit_outlined,
            fullWidth: true,
            onPressed: () => setState(() => _showSummary = false),
          ),
        ),
      ),
    );
  }

  Widget _staleBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.schedule, color: Color(0xFFF59E0B), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Hồ sơ đã lâu chưa cập nhật — khẩu vị có thể đã thay đổi, nên khai phá lại.',
              style: TextStyle(color: Color(0xFFFBBF24), fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summarySection(Map sec) {
    final items = (sec['items'] as List?) ?? const [];
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
          Text(
            sec['title']?.toString() ?? '',
            style: const TextStyle(
                color: AppColors.brandPrimaryDark,
                fontWeight: FontWeight.w700,
                fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final it in items) _summaryRow(it as Map),
        ],
      ),
    );
  }

  Widget _summaryRow(Map it) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(it['label']?.toString() ?? '',
                style: const TextStyle(
                    color: AppColors.darkTextSecondary, fontSize: 13.5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(it['value']?.toString() ?? '',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: AppColors.darkTextPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _traitsCard(List traits) {
    // Gộp theo nhóm: mỗi category chỉ 1 tiêu đề, liệt kê bullet; bỏ tiền tố "Khai phá:".
    final groups = <String, List<String>>{};
    final order = <String>[];
    for (final t in traits) {
      final m = t as Map;
      final label = (m['category_label']?.toString() ?? '')
          .replaceFirst(RegExp(r'^Khai phá:\s*'), '');
      final content = m['content']?.toString() ?? '';
      if (content.isEmpty) continue;
      if (!groups.containsKey(label)) {
        groups[label] = <String>[];
        order.add(label);
      }
      groups[label]!.add(content);
    }
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
          const Text('Đặc tính đã ghi nhận',
              style: TextStyle(
                  color: AppColors.brandPrimaryDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          const SizedBox(height: AppSpacing.sm),
          for (final label in order) ...[
            if (label.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 2),
                child: Text(label,
                    style: const TextStyle(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            for (final c in groups[label]!)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
                child: Text('• $c',
                    style: const TextStyle(
                        color: AppColors.darkTextSecondary,
                        fontSize: 13,
                        height: 1.4)),
              ),
          ],
        ],
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
