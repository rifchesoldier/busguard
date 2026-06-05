import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BgColors {
  static const ink = Color(0xFF1A1F3D);
  static const dusk = Color(0xFF3D405B);
  static const terracotta = Color(0xFFE07A5F);
  static const sage = Color(0xFF81B29A);
  static const gold = Color(0xFFF4A261);
  static const cream = Color(0xFFFDF8F3);
  static const sand = Color(0xFFF5EDE4);
  static const danger = Color(0xFFE63946);
  static const success = Color(0xFF2A9D8F);
}

class BgTheme {
  static ThemeData get light {
    final display = GoogleFonts.outfitTextTheme();
    final body = GoogleFonts.dmSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: BgColors.cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: BgColors.terracotta,
        primary: BgColors.ink,
        secondary: BgColors.gold,
        surface: Colors.white,
        error: BgColors.danger,
      ),
      textTheme: body.copyWith(
        displayLarge: display.displayLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: BgColors.ink,
        ),
        headlineMedium: display.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: BgColors.ink,
        ),
        titleLarge: display.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: BgColors.ink,
        ),
        bodyLarge: body.bodyLarge?.copyWith(color: BgColors.dusk),
        bodyMedium: body.bodyMedium?.copyWith(color: BgColors.dusk.withValues(alpha: 0.8)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: BgColors.ink,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: BgColors.ink,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BgColors.ink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: BgColors.dusk.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: BgColors.dusk.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: BgColors.terracotta, width: 2),
        ),
        hintStyle: GoogleFonts.dmSans(color: BgColors.dusk.withValues(alpha: 0.4)),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: BgColors.terracotta,
        unselectedItemColor: BgColors.dusk,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
    );
  }

  static BoxDecoration get heroGradient => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BgColors.ink, BgColors.dusk, BgColors.terracotta],
        ),
      );

  static BoxDecoration glassCard({Color? tint}) => BoxDecoration(
        color: (tint ?? Colors.white).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: BgColors.ink.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      );
}
