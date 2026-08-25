import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  // ─────────────────────────────────────────────
  // Display
  // ─────────────────────────────────────────────

  static const displayLarge = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -1.2,
    color: AppColors.textPrimary,
  );

  static const displayMedium = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.8,
    color: AppColors.textPrimary,
  );

  // ─────────────────────────────────────────────
  // Headings
  // ─────────────────────────────────────────────

  static const headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  static const headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const headingSmall = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  // ─────────────────────────────────────────────
  // Body
  // ─────────────────────────────────────────────

  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textMuted,
  );

  // ─────────────────────────────────────────────
  // Labels
  // ─────────────────────────────────────────────

  static const labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textSecondary,
  );

  static const labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.3,
    color: AppColors.textMuted,
  );
}