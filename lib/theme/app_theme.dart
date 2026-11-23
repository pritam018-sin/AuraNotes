import 'package:flutter/material.dart';

class AppTheme {
  // Global theme mode tracker
  static bool isDark = true;

  // Theme Colors (Static constants so const constructors compile cleanly)
  static const Color background = Color(0xFF08090C);
  static const Color surface = Color(0xFF0F1117);
  static const Color surfaceSecondary = Color(0xFF171A23);
  static const Color surfaceTertiary = Color(0xFF222634);
  static const Color sidebarBackground = Color(0xFF0B0D12);

  // Modern Accents (Harmonized with desktop icon)
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentViolet = Color(0xFF8B5CF6);
  static const Color accentRose = Color(0xFFEC4899);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentBlue = Color(0xFF3B82F6);

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);

  // Specular Borders & Glass Fills
  static const Color glassBorder = Color(0x22FFFFFF);
  static const Color glassBorderHover = Color(0x44FFFFFF);
  static const Color glassBorderActive = Color(0x8800E5FF);
  static const Color glassFill = Color(0xD910131B);
  static const Color glassFillLight = Color(0x1AFFFFFF);

  // Dynamic Theme Helpers (for responsive dark/light mode switching)
  static Color bg(bool dark) => dark ? background : const Color(0xFFF8FAFC);
  static Color surf(bool dark) => dark ? surface : const Color(0xFFFFFFFF);
  static Color surfSec(bool dark) => dark ? surfaceSecondary : const Color(0xFFF1F5F9);
  static Color txtPrimary(bool dark) => dark ? textPrimary : const Color(0xFF0F172A);
  static Color txtSecondary(bool dark) => dark ? textSecondary : const Color(0xFF475569);
  static Color txtTertiary(bool dark) => dark ? textTertiary : const Color(0xFF94A3B8);
  static Color border(bool dark) => dark ? glassBorder : const Color(0x18000000);

  // Window Controls
  static const Color trafficRed = Color(0xFFFF5F56);
  static const Color trafficYellow = Color(0xFFFFBD2E);
  static const Color trafficGreen = Color(0xFF27C93F);

  // Gradients (Harmonized with AuraNotes Icon)
  static const LinearGradient auraCyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00E5FF), Color(0xFF8B5CF6)],
  );

  static const LinearGradient auraVioletGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
  );

  static const LinearGradient auraAmberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x25FFFFFF), Color(0x08FFFFFF)],
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF08090C),
      primaryColor: const Color(0xFF00E5FF),
      fontFamily: 'Segoe UI',
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00E5FF),
        secondary: Color(0xFF8B5CF6),
        surface: Color(0xFF0F1117),
        onSurface: Color(0xFFF8FAFC),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(const Color(0x33FFFFFF)),
        radius: const Radius.circular(999),
        thickness: WidgetStateProperty.all(6),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF171A23),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x22FFFFFF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        textStyle: const TextStyle(
          color: Color(0xFFF8FAFC),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      primaryColor: const Color(0xFF0284C7),
      fontFamily: 'Segoe UI',
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0284C7),
        secondary: Color(0xFF7C3AED),
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF0F172A),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(const Color(0x33000000)),
        radius: const Radius.circular(999),
        thickness: WidgetStateProperty.all(6),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x18000000)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        textStyle: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }
}
