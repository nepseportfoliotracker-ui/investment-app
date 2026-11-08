import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens, mirrored from backtesting_app/candlestick_pattern/theme.py.
///
/// Rules of the system: one dark neutral base, one accent kept for primary
/// actions and focus, up/down only for money direction, hierarchy from weight
/// and size rather than extra colour, spacing on an 8px rhythm.
class T {
  // Surfaces: one base, one raised layer for menus/sheets, one hover tint.
  static const bg = Color(0xFF0D0F13);
  static const surface = Color(0xFF13161C);
  static const hover = Color(0xFF1A1E26);
  static const line = Color(0xFF22262F);

  // Text: three steps.
  static const textStrong = Color(0xFFF4F5F7);
  static const text = Color(0xFFC8CBD2);
  static const muted = Color(0xFF8A8F9A);
  static const faint = Color(0xFF555B66);

  // The single accent.
  static const accent = Color(0xFF2F6BFF);
  static const accentHover = Color(0xFF4A7FFF);

  // Semantic, data only.
  static const up = Color(0xFF26A69A);
  static const down = Color(0xFFEF5350);
  static const warn = Color(0xFFF0A63A);

  static const radius = 4.0;

  // Type scale (size / line-height on the 8px grid).
  static const fsXs = 11.0;
  static const fsSm = 13.0;
  static const fsMd = 15.0;
  static const fsLg = 20.0;
  static const fsXl = 32.0;

  static TextStyle sans({
    double size = fsSm,
    FontWeight weight = FontWeight.w400,
    Color color = text,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.ibmPlexSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  static TextStyle mono({
    double size = 12,
    FontWeight weight = FontWeight.w400,
    Color color = text,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.ibmPlexMono(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Green for gains, red for losses.
  static Color direction(num v) => v >= 0 ? up : down;
}

ThemeData appTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(T.radius),
  );
  final textTheme = GoogleFonts.ibmPlexSansTextTheme(
    base.textTheme,
  ).apply(bodyColor: T.text, displayColor: T.textStrong);

  return base.copyWith(
    scaffoldBackgroundColor: T.bg,
    canvasColor: T.bg,
    colorScheme: const ColorScheme.dark(
      primary: T.accent,
      onPrimary: Colors.white,
      secondary: T.accent,
      onSecondary: Colors.white,
      surface: T.bg,
      onSurface: T.text,
      surfaceContainerLowest: T.bg,
      surfaceContainerLow: T.surface,
      surfaceContainer: T.surface,
      surfaceContainerHigh: T.surface,
      surfaceContainerHighest: T.hover,
      onSurfaceVariant: T.muted,
      outline: T.line,
      outlineVariant: T.line,
      error: T.down,
      onError: Colors.white,
      errorContainer: T.surface,
      onErrorContainer: T.down,
    ),
    textTheme: textTheme.copyWith(
      bodyMedium: T.sans(),
      bodySmall: T.sans(size: 12, color: T.muted),
      titleLarge: T.sans(
        size: T.fsLg,
        weight: FontWeight.w600,
        color: T.textStrong,
      ),
      titleMedium: T.sans(
        size: T.fsMd,
        weight: FontWeight.w600,
        color: T.textStrong,
      ),
      labelLarge: T.sans(weight: FontWeight.w600),
    ),
    dividerTheme: const DividerThemeData(color: T.line, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: T.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: T.muted,
      titleTextStyle: T.sans(
        weight: FontWeight.w600,
        color: T.textStrong,
        letterSpacing: 13 * .08,
      ),
      shape: const Border(bottom: BorderSide(color: T.line)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: T.bg,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      elevation: 0,
      height: 64,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => T.sans(
          size: 12,
          weight: s.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? T.textStrong : T.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          size: 22,
          color: s.contains(WidgetState.selected) ? T.accent : T.muted,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      labelStyle: T.sans(size: 12, color: T.muted),
      floatingLabelStyle: T.sans(size: 12, color: T.muted),
      hintStyle: T.sans(color: T.faint),
      errorStyle: T.sans(size: 12, color: T.down),
      border: const UnderlineInputBorder(borderSide: BorderSide(color: T.line)),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: T.line),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: T.accent),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: T.down),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: T.down),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: T.accent,
      selectionColor: T.accent.withValues(alpha: .35),
      selectionHandleColor: T.accent,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: T.accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: T.accent.withValues(alpha: .4),
        disabledForegroundColor: Colors.white70,
        shape: shape,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: T.sans(weight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: T.muted,
        shape: shape,
        textStyle: T.sans(weight: FontWeight.w500),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: T.text,
        side: const BorderSide(color: T.line),
        shape: shape,
        textStyle: T.sans(weight: FontWeight.w500),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: T.muted),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: T.accent,
      foregroundColor: Colors.white,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: shape,
      extendedTextStyle: T.sans(weight: FontWeight.w600),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: T.surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: T.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(T.radius)),
        side: BorderSide(color: T.line),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: T.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(T.radius),
        side: const BorderSide(color: T.line),
      ),
      titleTextStyle: T.sans(
        size: T.fsLg,
        weight: FontWeight.w600,
        color: T.textStrong,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: T.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(T.radius),
        side: const BorderSide(color: T.line),
      ),
      textStyle: T.sans(weight: FontWeight.w500),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: T.surface,
      contentTextStyle: T.sans(color: T.textStrong),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(T.radius),
        side: const BorderSide(color: T.line),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: T.accent,
      refreshBackgroundColor: T.surface,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: T.muted,
      textColor: T.text,
      titleTextStyle: T.sans(weight: FontWeight.w500, color: T.text),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: T.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(T.radius),
      ),
    ),
  );
}
