import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Main: #D3DA95 (Sage Green / Xanh vàng)
  static const Color primary = Color(0xFFD3DA95);
  static const Color primaryDark = Color(0xFFB8C078);
  static const Color primaryLight = Color(0xFFE5EAB8);

  // Accent Colors - Contrast: #151416 (Charcoal / Đen tro)
  static const Color accent = Color(0xFF151416);
  static const Color accentLight = Color(0xFF2D2D30);
  static const Color accentMuted = Color(0xFF4A4A4D);

  // Secondary Colors (complementary)
  static const Color secondary = Color(0xFF8B9A6D);
  static const Color secondaryDark = Color(0xFF6B7A50);
  static const Color secondaryLight = Color(0xFFA8B88A);

  // Background Colors
  static const Color background = Color(0xFFFAFAF8);
  static const Color backgroundDark = Color(0xFF151416);
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF1E1E20);

  // Text Colors
  static const Color textPrimary = Color(0xFF151416);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Colors.white;
  static const Color textDark = Color(0xFF151416);
  static const Color textOnPrimary = Color(0xFF151416);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Neutral Colors
  static const Color gray50 = Color(0xFFFAFAF8);
  static const Color gray100 = Color(0xFFF5F5F3);
  static const Color gray200 = Color(0xFFE8E8E5);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF151416);

  // Gradient (subtle)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentMuted],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
