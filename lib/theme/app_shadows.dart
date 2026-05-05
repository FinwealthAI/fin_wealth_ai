import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppShadows {
  AppShadows._();

  static const card = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const cardHover = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const purpleGlow = [
    BoxShadow(
      color: AppColors.purpleGlow,
      blurRadius: 20,
      spreadRadius: 0,
      offset: Offset(0, 0),
    ),
  ];

  static const subtle = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
}
