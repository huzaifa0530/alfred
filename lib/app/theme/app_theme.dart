import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData dark() {
    final colorScheme = const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.white,

      secondary: AppColors.primarySoft,
      onSecondary: AppColors.white,

      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,

      error: AppColors.error,
      onError: AppColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: colorScheme,

      scaffoldBackgroundColor: AppColors.background,

      fontFamily: 'Inter',

      textTheme: const TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,

        headlineLarge: AppTextStyles.headingLarge,
        headlineMedium: AppTextStyles.headingMedium,
        headlineSmall: AppTextStyles.headingSmall,

        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,

        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusLarge,
          ),
          side: const BorderSide(
            color: AppColors.borderSubtle,
            width: AppDimensions.borderWidth,
          ),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space16,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusMedium,
          ),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusMedium,
          ),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusMedium,
          ),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusMedium,
          ),
          borderSide: const BorderSide(
            color: AppColors.error,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusMedium,
          ),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),

        hintStyle: AppTextStyles.bodyMedium,

        labelStyle: AppTextStyles.bodyMedium,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(
            double.infinity,
            AppDimensions.buttonHeight,
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppDimensions.radiusMedium,
            ),
          ),

          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            double.infinity,
            AppDimensions.buttonHeight,
          ),
          foregroundColor: AppColors.textPrimary,

          side: const BorderSide(
            color: AppColors.border,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppDimensions.radiusMedium,
            ),
          ),

          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          minimumSize: const Size(
            AppDimensions.iconButtonSize,
            AppDimensions.iconButtonSize,
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevated,
        selectedColor: AppColors.primaryContainer,
        disabledColor: AppColors.surface,

        side: const BorderSide(
          color: AppColors.border,
        ),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusSmall,
          ),
        ),

        labelStyle: AppTextStyles.labelMedium,

        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space8,
          vertical: AppDimensions.space4,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryContainer,

        labelTextStyle: WidgetStateProperty.all(
          AppTextStyles.labelSmall,
        ),

        iconTheme: WidgetStateProperty.all(
          const IconThemeData(size: 22),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusXLarge,
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: AppTextStyles.bodyMedium,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusMedium,
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}