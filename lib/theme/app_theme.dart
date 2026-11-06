import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ParkSnap tactical dark theme system inspired by the Stitch "Tactical Field Utility" design.
/// Colors: deep navy canvas, emerald primary, amber secondary, monospace labels.
class AppTheme {
  AppTheme._();

  // ─── Color Palette ───────────────────────────────────────────────────────────

  static const Color background = Color(0xFF0B1326);
  static const Color surface = Color(0xFF0B1326);
  static const Color surfaceContainerLow = Color(0xFF131B2E);
  static const Color surfaceContainer = Color(0xFF171F33);
  static const Color surfaceContainerHigh = Color(0xFF222A3D);
  static const Color surfaceContainerHighest = Color(0xFF2D3449);

  /// Emerald primary — scan confirmation, status active, primary buttons
  static const Color primary = Color(0xFF4EDEA3);
  static const Color primaryContainer = Color(0xFF10B981);
  static const Color onPrimary = Color(0xFF003824);

  /// Amber secondary — visitor tags, warnings, time alerts
  static const Color secondary = Color(0xFFFFB95F);
  static const Color secondaryContainer = Color(0xFFEE9800);
  static const Color onSecondary = Color(0xFF472A00);

  /// Error / Exited
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);

  /// Text
  static const Color onSurface = Color(0xFFDAE2FD);
  static const Color onSurfaceVariant = Color(0xFFBBCABF);
  static const Color outline = Color(0xFF86948A);
  static const Color outlineVariant = Color(0xFF3C4A42);

  // ─── Status Colors ───────────────────────────────────────────────────────────

  static const Color statusInside = Color(0xFF10B981);
  static const Color statusExited = Color(0xFF64748B);
  static const Color statusInsideBg = Color(0x1A10B981);
  static const Color statusExitedBg = Color(0x1A64748B);

  // ─── Confidence Colors ───────────────────────────────────────────────────────

  static Color confidenceColor(double confidence) {
    if (confidence >= 80) return const Color(0xFF10B981);
    if (confidence >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  // ─── Typography ──────────────────────────────────────────────────────────────

  static TextStyle get headlineLg => GoogleFonts.chivo(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: onSurface,
        height: 1.25,
      );

  static TextStyle get headlineMd => GoogleFonts.chivo(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: onSurface,
        height: 1.27,
      );

  static TextStyle get headlineSm => GoogleFonts.chivo(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: onSurface,
        height: 1.33,
      );

  static TextStyle get bodyLg => GoogleFonts.chivo(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: onSurface,
        height: 1.5,
      );

  static TextStyle get bodyMd => GoogleFonts.chivo(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: onSurfaceVariant,
        height: 1.43,
      );

  /// License plate monospace display style
  static TextStyle get plateDisplay => GoogleFonts.jetBrainsMono(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: onSurface,
        letterSpacing: 0.1,
        height: 1.27,
      );

  static TextStyle get plateLg => GoogleFonts.jetBrainsMono(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: onSurface,
        letterSpacing: 0.12,
        height: 1.21,
      );

  static TextStyle get labelLg => GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onSurfaceVariant,
        letterSpacing: 0.04,
        height: 1.43,
      );

  static TextStyle get labelMd => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: onSurfaceVariant,
        letterSpacing: 0.05,
        height: 1.33,
      );

  static TextStyle get labelSm => GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: onSurfaceVariant,
        letterSpacing: 0.06,
        height: 1.4,
      );

  // ─── Theme Data ──────────────────────────────────────────────────────────────

  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          surface: surface,
          primary: primary,
          onPrimary: onPrimary,
          primaryContainer: primaryContainer,
          secondary: secondary,
          onSecondary: onSecondary,
          secondaryContainer: secondaryContainer,
          error: error,
          errorContainer: errorContainer,
          onSurface: onSurface,
          onSurfaceVariant: onSurfaceVariant,
          outline: outline,
          outlineVariant: outlineVariant,
        ),
        textTheme: GoogleFonts.chivoTextTheme(
          ThemeData.dark().textTheme,
        ).apply(bodyColor: onSurface, displayColor: onSurface),
        appBarTheme: AppBarTheme(
          backgroundColor: background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: headlineSm.copyWith(color: onSurface),
          iconTheme: const IconThemeData(color: onSurface),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceContainerLow,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: outlineVariant, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: outlineVariant, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: error, width: 1.5),
          ),
          labelStyle: labelMd.copyWith(color: onSurfaceVariant),
          hintStyle: labelMd.copyWith(color: outline),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryContainer,
            foregroundColor: onPrimary,
            minimumSize: const Size(double.infinity, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: GoogleFonts.chivo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: onSurface,
            minimumSize: const Size(double.infinity, 52),
            side: const BorderSide(color: outlineVariant, width: 1.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: GoogleFonts.chivo(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: surfaceContainer,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: outlineVariant, width: 1),
          ),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        ),
        dividerTheme: const DividerThemeData(
          color: outlineVariant,
          thickness: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: surfaceContainerHighest,
          contentTextStyle: bodyMd.copyWith(color: onSurface),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          behavior: SnackBarBehavior.floating,
        ),
      );
}
