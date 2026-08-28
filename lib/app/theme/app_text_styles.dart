import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  // ════════════════════════════════════════════════════════════
  // ALFRED BRANDING
  // ════════════════════════════════════════════════════════════

  /// Elegant Alfred identity.
  static const brand = TextStyle(
    fontFamily: 'Cinzel',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 1.2,
    color: AppColors.textPrimary,
  );

  /// Small futuristic system/status text.
  static const system = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.8,
    color: AppColors.textSecondary,
  );

  // ════════════════════════════════════════════════════════════
  // DISPLAY
  // Rajdhani = Alfred dashboard personality
  // ════════════════════════════════════════════════════════════

  static const displayLarge = TextStyle(
    fontFamily: 'Rajdhani',
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.05,
    letterSpacing: -0.8,
    color: AppColors.textPrimary,
  );

  static const displayMedium = TextStyle(
    fontFamily: 'Rajdhani',
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  // ════════════════════════════════════════════════════════════
  // HEADINGS
  // ════════════════════════════════════════════════════════════

  static const headingLarge = TextStyle(
    fontFamily: 'Rajdhani',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static const headingMedium = TextStyle(
    fontFamily: 'Rajdhani',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static const headingSmall = TextStyle(
    fontFamily: 'Rajdhani',
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  // ════════════════════════════════════════════════════════════
  // BODY
  // Inter = maximum readability
  // ════════════════════════════════════════════════════════════

  static const bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  static const bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textMuted,
  );

  // ════════════════════════════════════════════════════════════
  // LABELS
  // Inter = clean UI
  // ════════════════════════════════════════════════════════════

  static const labelLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const labelMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textSecondary,
  );

  static const labelSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.3,
    color: AppColors.textMuted,
  );

  // ════════════════════════════════════════════════════════════
  // SPECIAL ALFRED NUMBERS
  // Orbitron should be used sparingly.
  // ════════════════════════════════════════════════════════════

  static const stat = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  static const statLarge = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  static const status = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.8,
    color: AppColors.textSecondary,
  );
}
