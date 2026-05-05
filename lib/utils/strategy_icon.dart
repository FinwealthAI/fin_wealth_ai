import 'package:flutter/material.dart';
import '../theme/theme.dart';

IconData strategyIconFromName(String? lucideName) {
  switch (lucideName) {
    case 'trending-up':
      return Icons.trending_up;
    case 'building-2':
      return Icons.business_outlined;
    case 'gem':
      return Icons.diamond_outlined;
    case 'shield-check':
      return Icons.verified_user_outlined;
    case 'coins':
      return Icons.savings_outlined;
    case 'network':
      return Icons.hub_outlined;
    case 'package-plus':
      return Icons.layers_outlined;
    case 'zap':
      return Icons.bolt;
    case 'rotate-ccw':
      return Icons.replay;
    case 'arrow-down-to-dot':
      return Icons.south;
    case 'anchor':
      return Icons.anchor;
    default:
      return Icons.flag_outlined;
  }
}

Color strategyAccentFromColor(String? tailwindColor) {
  switch (tailwindColor) {
    case 'amber':
    case 'orange':
      return AppColors.warningDark;
    case 'cyan':
    case 'blue':
      return AppColors.brandSecondaryDark;
    case 'emerald':
      return AppColors.successDark;
    case 'rose':
      return AppColors.dangerDark;
    case 'indigo':
    case 'purple':
    default:
      return AppColors.brandPrimaryDark;
  }
}
