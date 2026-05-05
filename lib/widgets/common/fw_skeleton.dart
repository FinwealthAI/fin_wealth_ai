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
            gradient: LinearGradient(
              colors: const [
                AppColors.darkSurface,
                AppColors.darkSurfaceElevated,
                AppColors.darkSurface,
              ],
              stops: [0.0, _ctrl.value, 1.0],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        );
      },
    );
  }
}
