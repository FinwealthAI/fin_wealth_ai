import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Một bước trong tour hướng dẫn: trỏ tới widget gắn [key], kèm tiêu đề & mô tả.
class CoachStep {
  final GlobalKey key;
  final String title;
  final String body;

  /// Highlight dạng tròn (nút icon / FAB / nút gửi) thay vì bo góc chữ nhật.
  final bool circle;

  const CoachStep(this.key, this.title, this.body, {this.circle = false});
}

/// Một mục lợi ích hiển thị trong welcome dialog.
class OnboardBenefit {
  final IconData icon;
  final String title;
  final String body;
  const OnboardBenefit(this.icon, this.title, this.body);
}

const List<OnboardBenefit> kChatBenefits = [
  OnboardBenefit(Icons.travel_explore, 'Săn cơ hội khắp thị trường',
      'Hỏi mã nào đang có tín hiệu mua, ngành nào đang mạnh — Mr.Wealth quét & gợi ý cho bạn.'),
  OnboardBenefit(Icons.insights, 'Thẩm định trước khi xuống tiền',
      'Định giá, điểm mạnh – yếu & rủi ro của từng mã, tổng hợp từ dữ liệu & báo cáo.'),
  OnboardBenefit(Icons.account_balance_wallet_outlined, 'Đánh giá & bảo vệ danh mục',
      'Soi sức khỏe danh mục, cảnh báo rủi ro, gợi ý nên giữ hay cơ cấu lại.'),
];

/// Welcome dialog dùng chung. Trả về `true` nếu user chọn xem tour,
/// `false` nếu bỏ qua.
Future<bool> showOnboardingWelcome(
  BuildContext context, {
  required String title,
  required String subtitle,
  List<OnboardBenefit> benefits = const [],
  String ctaLabel = 'Dẫn tôi một vòng (30 giây)',
  String skipLabel = 'Để sau, tôi tự khám phá',
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (_) => _WelcomeDialog(
      title: title,
      subtitle: subtitle,
      benefits: benefits,
      ctaLabel: ctaLabel,
      skipLabel: skipLabel,
    ),
  );
  return result ?? false;
}

/// Welcome dialog cho màn Chat (chi tiết, có 3 lợi ích).
Future<bool> showChatWelcomeDialog(BuildContext context) => showOnboardingWelcome(
      context,
      title: 'Chào mừng đến Finwealth 👋',
      subtitle:
          'Nơi bạn đặt câu hỏi để tìm cơ hội, thẩm định cổ phiếu và ra quyết định đầu tư có cơ sở — thay vì phỏng đoán. Dành 30 giây để mình chỉ bạn cách dùng nhé!',
      benefits: kChatBenefits,
    );

/// Welcome dialog cấp ứng dụng (ngắn gọn, giới thiệu tổng quan).
Future<bool> showAppWelcomeDialog(BuildContext context) => showOnboardingWelcome(
      context,
      title: 'Chào mừng đến Finwealth 👋',
      subtitle:
          'Nền tảng đầu tư AI toàn diện. Cùng dạo nhanh 30 giây để biết mỗi khu vực giúp gì cho hành trình đầu tư của bạn nhé!',
      ctaLabel: 'Dạo một vòng (30 giây)',
    );

class _WelcomeDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<OnboardBenefit> benefits;
  final String ctaLabel;
  final String skipLabel;

  const _WelcomeDialog({
    required this.title,
    required this.subtitle,
    required this.benefits,
    required this.ctaLabel,
    required this.skipLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B2036), AppColors.darkSurface],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.25)),
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 40, offset: Offset(0, 20)),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                  ),
                  boxShadow: [BoxShadow(color: AppColors.purpleGlow, blurRadius: 24)],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/mr_wealth_avatar.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.auto_awesome, color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: AppColors.darkTextSecondary,
                ),
              ),
              if (benefits.isNotEmpty) ...[
                const SizedBox(height: 18),
                ...benefits.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _BenefitRow(b),
                    )),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_fix_high, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(ctaLabel,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(skipLabel,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkTextMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final OnboardBenefit b;
  const _BenefitRow(this.b);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(b.icon, size: 18, color: AppColors.brandPrimaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkTextPrimary,
                        height: 1.3)),
                const SizedBox(height: 2),
                Text(b.body,
                    style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.darkTextSecondary,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chạy tour spotlight qua [steps]. Tự bỏ bước có widget không tồn tại
/// (key.currentContext == null). [onDone] gọi khi xong hoặc bị bỏ qua.
void runCoachMarks(
  BuildContext context,
  List<CoachStep> steps, {
  required VoidCallback onDone,
}) {
  final visible = steps.where((s) => s.key.currentContext != null).toList();
  if (visible.isEmpty) {
    onDone();
    return;
  }
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  void finish() {
    entry.remove();
    onDone();
  }

  entry = OverlayEntry(
    builder: (_) => _CoachOverlay(steps: visible, onFinish: finish),
  );
  overlay.insert(entry);
}

class _CoachOverlay extends StatefulWidget {
  final List<CoachStep> steps;
  final VoidCallback onFinish;
  const _CoachOverlay({required this.steps, required this.onFinish});

  @override
  State<_CoachOverlay> createState() => _CoachOverlayState();
}

class _CoachOverlayState extends State<_CoachOverlay> {
  int _i = 0;
  Rect? _rect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    if (!mounted) return;
    final ctx = widget.steps[_i].key.currentContext;
    if (ctx == null) {
      _advance(); // bước này biến mất → nhảy tiếp
      return;
    }
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      _advance();
      return;
    }
    final pos = box.localToGlobal(Offset.zero);
    setState(() => _rect = (pos & box.size).inflate(8));
  }

  void _advance() {
    if (_i >= widget.steps.length - 1) {
      widget.onFinish();
      return;
    }
    setState(() {
      _i++;
      _rect = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final rect = _rect;
    final step = widget.steps[_i];
    final last = _i == widget.steps.length - 1;

    // Vị trí thẻ chú thích: dưới vùng highlight nếu highlight nằm nửa trên,
    // ngược lại đặt phía trên. Chưa đo được rect → đặt giữa màn.
    double? cardTop;
    double? cardBottom;
    if (rect == null) {
      cardTop = size.height * 0.4;
    } else if (rect.center.dy < size.height * 0.5) {
      cardTop = rect.bottom + 16;
    } else {
      cardBottom = size.height - rect.top + 16;
    }

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Scrim + lỗ khoét (chặn chạm xuyên xuống nút bên dưới).
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {}, // nuốt chạm
              child: CustomPaint(
                painter: _HolePainter(
                  rect,
                  step.circle ? (rect?.shortestSide ?? 0) / 2 : 14,
                  Colors.black.withValues(alpha: 0.74),
                ),
              ),
            ),
          ),
          // Thẻ chú thích.
          Positioned(
            left: 16,
            right: 16,
            top: cardTop,
            bottom: cardBottom,
            child: _TipCard(
              title: step.title,
              body: step.body,
              index: _i,
              total: widget.steps.length,
              last: last,
              onNext: _advance,
              onSkip: widget.onFinish,
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String title;
  final String body;
  final int index;
  final int total;
  final bool last;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _TipCard({
    required this.title,
    required this.body,
    required this.index,
    required this.total,
    required this.last,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.35)),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 28, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkTextPrimary)),
          const SizedBox(height: 6),
          Text(body,
              style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: AppColors.darkTextSecondary)),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('${index + 1}/$total',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkTextMuted)),
              const Spacer(),
              if (!last)
                TextButton(
                  onPressed: onSkip,
                  child: const Text('Bỏ qua',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkTextMuted)),
                ),
              const SizedBox(width: 4),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: onNext,
                child: Text(last ? 'Bắt đầu dùng' : 'Tiếp',
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HolePainter extends CustomPainter {
  final Rect? hole;
  final double radius;
  final Color scrim;
  const _HolePainter(this.hole, this.radius, this.scrim);

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Offset.zero & size);
    if (hole == null) {
      canvas.drawPath(full, Paint()..color = scrim);
      return;
    }
    final rr = RRect.fromRectAndRadius(hole!, Radius.circular(radius));
    final holePath = Path()..addRRect(rr);
    final diff = Path.combine(PathOperation.difference, full, holePath);
    canvas.drawPath(diff, Paint()..color = scrim);
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = AppColors.brandPrimaryDark,
    );
  }

  @override
  bool shouldRepaint(_HolePainter old) =>
      old.hole != hole || old.radius != radius;
}
