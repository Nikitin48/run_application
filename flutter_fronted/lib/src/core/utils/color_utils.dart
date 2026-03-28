import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

Color colorFromHexOrDefault(
  String? hex, {
  Color fallback = AppColors.blue3399,
}) {
  if (hex == null || !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(hex)) {
    return fallback;
  }
  final value = int.parse(hex.substring(1), radix: 16);
  return Color(0xFF000000 | value);
}

String hexFromColor(Color color) {
  final rgb = color.toARGB32() & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
