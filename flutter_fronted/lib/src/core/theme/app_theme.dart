import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData theme() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.blue3399,
          brightness: Brightness.dark,
        ).copyWith(
          surface: AppColors.background,
          onSurface: AppColors.text,
          onSurfaceVariant: AppColors.text,
          primary: AppColors.blue3399,
          onPrimary: Color(0xFFFFFFFF),
          primaryContainer: Color(0xFF243040),
          onPrimaryContainer: AppColors.secondPrimary,
          secondary: AppColors.secondPrimary,
          onSecondary: AppColors.background,
          tertiary: AppColors.purple8C3,
          onTertiary: Color(0xFFFFFFFF),
          surfaceContainerLowest: AppColors.background,
          surfaceContainerLow: Color(0xFF191D24),
          surfaceContainer: Color(0xFF1C2028),
          surfaceContainerHigh: Color(0xFF1F242C),
          surfaceContainerHighest: Color(0xFF252B34),
          outline: Color(0xFF3D4450),
          outlineVariant: Color(0xFF2E343F),
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.text),
        actionsIconTheme: IconThemeData(color: AppColors.text),
      ),
      iconTheme: IconThemeData(color: AppColors.text),
      primaryIconTheme: IconThemeData(color: AppColors.text),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.text,
        textColor: AppColors.text,
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outlineVariant),
      dialogTheme: DialogThemeData(backgroundColor: AppColors.background),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        contentTextStyle: TextStyle(color: AppColors.text),
        actionTextColor: AppColors.secondPrimary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.blue3399,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.secondPrimary, width: 1.5),
        ),
        labelStyle: TextStyle(color: AppColors.text),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return TextStyle(color: AppColors.secondPrimary);
          }
          return TextStyle(color: AppColors.text);
        }),
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return AppColors.secondPrimary;
          }
          return AppColors.text;
        }),
        suffixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return AppColors.secondPrimary;
          }
          return AppColors.text;
        }),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: 0,
        color: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.background;
            }
            return AppColors.text;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.secondPrimary;
            }
            return Colors.transparent;
          }),
          side: WidgetStateProperty.all(
            BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
      ),
    );
  }
}
