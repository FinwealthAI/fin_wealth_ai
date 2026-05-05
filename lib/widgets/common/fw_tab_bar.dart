import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class FwSegmentedTabs extends StatelessWidget {
  final List<String> tabs;
  final int active;
  final ValueChanged<int> onChanged;

  const FwSegmentedTabs({
    super.key,
    required this.tabs,
    required this.active,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isActive = i == active;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.brandPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  boxShadow: isActive ? AppShadows.purpleGlow : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? Colors.white
                        : AppColors.darkTextSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
