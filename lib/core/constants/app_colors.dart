import 'package:flutter/material.dart';

class AppColors {
  // Primary Navy & Dark Blue Palette (Elegant, Prestigious & Cohesive)
  static const Color primary = Color(0xFF0B1E36);      // Deep Midnight Navy
  static const Color primaryDark = Color(0xFF061120);  // Deepest Navy Tone
  static const Color primaryLight = Color(0xFF16325B); // Rich Classic Navy
  static const Color secondary = Color(0xFF1B3C68);    // Elegant Slate Navy (harmonious with primary)
  static const Color accent = Color(0xFF2563EB);       // Royal Blue Accent
  static const Color accentLight = Color(0xFFDBEAFE);  // Soft Royal Blue Tint

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color navySurface = Color(0xFF0F2646);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // Status Colors & Aliases
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color hadirBg = Color(0xFFD1FAE5);
  static const Color hadirText = Color(0xFF047857);

  static const Color info = Color(0xFF0284C7);
  static const Color infoLight = Color(0xFFE0F2FE);
  static const Color infoText = Color(0xFF0369A1);
  static const Color izinBg = Color(0xFFE0F2FE);
  static const Color izinText = Color(0xFF0369A1);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color sakitBg = Color(0xFFFEF3C7);
  static const Color sakitText = Color(0xFFB45309);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color tidakHadirBg = Color(0xFFFEE2E2);
  static const Color tidakHadirText = Color(0xFFB91C1C);

  static const Color belumAbsenBg = Color(0xFFF1F5F9);
  static const Color belumAbsenText = Color(0xFF64748B);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color inputBorder = Color(0xFFCBD5E1);

  // Shadow & Gradients
  static const Color shadow = Color(0x0C0B1E36);
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0B1E36), Color(0xFF1B3C68)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient navyHeroGradient = LinearGradient(
    colors: [Color(0xFF061120), Color(0xFF0B1E36), Color(0xFF16325B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
