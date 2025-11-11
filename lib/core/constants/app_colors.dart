import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6B4EFF);
  static const Color primaryDark = Color(0xFF5538EE);
  static const Color primaryLight = Color(0xFF9B8AFF);

  // Secondary Colors
  static const Color secondary = Color(0xFFFF6B9D);
  static const Color secondaryDark = Color(0xFFE5528A);
  static const Color secondaryLight = Color(0xFFFF9CB8);

  // Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF1A1A2E);
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF252540);

  // Text Colors
  static const Color textPrimary = Color(0xFF2D3142);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Colors.white;
  static const Color textDark = Color(0xFF1F2937);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Neutral Colors
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
