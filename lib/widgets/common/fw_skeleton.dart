import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class FwSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const FwSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AppRadius.sm,
  });

  const FwSkeleton.card({super.key})
      : width = double.infinity,
        height = 120,
        radius = AppRadius.lg;

  const FwSkeleton.line({super.key, this.width})
      : height = 14,
        radius = AppRadius.sm;

  /// Nền và dải sáng của shimmer. Highlight phải đủ tương phản với nền —
  /// nếu dùng cặp darkSurface/darkSurfaceElevated thì mắt thường không thấy
  /// chuyển động (nhìn như khối tĩnh).
  static const Color _base = AppColors.darkSurface;
  static const Color _highlight = Color(0xFF2A3046);

  /// Gradient shimmer dùng chung cho mọi skeleton (kể cả skeleton tự dựng
  /// ngoài widget này): dải sáng hẹp quét chéo từ trái sang phải theo [t]
  /// (0→1, lặp lại). Truyền `controller.value` của một AnimationController
  /// đang `repeat()`.
  static LinearGradient shimmerGradient(double t) {
    final dx = -1.5 + 3.0 * t;
    return LinearGradient(
      begin: Alignment(dx - 1.0, -0.2),
      end: Alignment(dx + 1.0, 0.2),
      colors: const [_base, _highlight, _base],
      stops: const [0.35, 0.5, 0.65],
    );
  }

  @override
  State<FwSkeleton> createState() => _FwSkeletonState();
}

class _FwSkeletonState extends State<FwSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: FwSkeleton.shimmerGradient(_ctrl.value),
          ),
        );
      },
    );
  }
}
