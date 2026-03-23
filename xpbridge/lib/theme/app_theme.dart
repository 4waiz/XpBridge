import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static const Color background = Color(0xFFF7F7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFF0F1ED);
  static const Color surfaceMuted = cardBackground;

  static const Color primary = Color(0xFF2EC4B6);
  static const Color primaryDark = Color(0xFF22A89B);
  static const Color primaryLight = Color(0xFFE5F7F4);

  static const Color text = Color(0xFF1F2933);
  static const Color textSecondary = Color(0xFF5F6C76);
  static const Color textMuted = Color(0xFF7B8794);
  static const Color border = Color(0xFFE7EAE6);

  static const Color success = Color(0xFF7BCFA6);
  static const Color successDark = Color(0xFF3D9B72);
  static const Color warning = Color(0xFFF3B64C);
  static const Color error = Color(0xFFE76F51);

  static const double cornerRadius = 24;
  static const double cornerRadiusSmall = 20;
  static const double cornerRadiusLarge = 32;
  static const double fieldRadius = 20;
  static const double pillRadius = 999;

  static ThemeData get light {
    final baseTextTheme = GoogleFonts.manropeTextTheme();
    final textTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: text,
        height: 1.05,
        letterSpacing: -1.2,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: text,
        height: 1.08,
        letterSpacing: -0.8,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: text,
        height: 1.08,
        letterSpacing: -0.7,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: text,
        height: 1.1,
        letterSpacing: -0.5,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: text,
        height: 1.12,
        letterSpacing: -0.35,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: text,
        height: 1.2,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: text,
        height: 1.2,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: text,
        height: 1.2,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        color: text,
        height: 1.5,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
        color: text,
        height: 1.5,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w500,
        color: textSecondary,
        height: 1.45,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: text,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: textSecondary,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: textMuted,
      ),
    );

    final colorScheme = const ColorScheme.light().copyWith(
      primary: primary,
      onPrimary: text,
      secondary: primaryDark,
      onSecondary: surface,
      surface: surface,
      onSurface: text,
      error: error,
      onError: surface,
      outline: border,
      outlineVariant: border,
      surfaceContainerHighest: cardBackground,
      shadow: text.withValues(alpha: 0.08),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      cardColor: surface,
      canvasColor: background,
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
      dividerColor: border,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          minimumSize: const Size.fromHeight(58),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          backgroundColor: primary,
          foregroundColor: text,
          disabledBackgroundColor: cardBackground,
          disabledForegroundColor: textMuted,
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pillRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(58),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          foregroundColor: text,
          side: const BorderSide(color: border),
          backgroundColor: surface,
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pillRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: text,
          textStyle: textTheme.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardBackground,
        disabledColor: cardBackground,
        selectedColor: primaryLight,
        secondarySelectedColor: primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(pillRadius),
          side: BorderSide.none,
        ),
        labelStyle: textTheme.labelMedium?.copyWith(color: text),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: text),
        brightness: Brightness.light,
        side: BorderSide.none,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: textMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
        helperStyle: textTheme.bodySmall?.copyWith(color: textSecondary),
        errorStyle: textTheme.bodySmall?.copyWith(color: error),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: BorderSide(
            color: primary.withValues(alpha: 0.45),
            width: 1.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: BorderSide(
            color: error.withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: BorderSide(
            color: error.withValues(alpha: 0.6),
            width: 1.2,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadiusLarge),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: text,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: surface),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadiusSmall),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? surface : textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? primary
              : cardBackground;
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: text,
        elevation: 0,
        extendedTextStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(pillRadius),
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
        activeTrackColor: primary,
        inactiveTrackColor: cardBackground,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.14),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: cardBackground,
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        labelColor: text,
        unselectedLabelColor: textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: text.withValues(alpha: 0.04),
      blurRadius: 32,
      offset: const Offset(0, 16),
      spreadRadius: -18,
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: text.withValues(alpha: 0.08),
      blurRadius: 50,
      offset: const Offset(0, 26),
      spreadRadius: -24,
    ),
  ];

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: text.withValues(alpha: 0.035),
      blurRadius: 22,
      offset: const Offset(0, 10),
      spreadRadius: -12,
    ),
  ];

  static List<BoxShadow> get floatingShadow => [
    BoxShadow(
      color: text.withValues(alpha: 0.07),
      blurRadius: 40,
      offset: const Offset(0, 18),
      spreadRadius: -18,
    ),
  ];
}

class AppSpacing {
  const AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 28;
  static const double xxxl = 32;
  static const double page = 24;
  static const double pageWide = 28;
}

extension ColorWithOpacity on Color {
  Color get light => withValues(alpha: 0.1);
  Color get medium => withValues(alpha: 0.2);
  Color get soft => withValues(alpha: 0.05);
}
