import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static const Color background = Color(0xFFF7F7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF2EC4B6);
  static const Color primaryDark = Color(0xFF159C92);
  static const Color primaryDeep = Color(0xFF0B6662);
  static const Color primaryLight = Color(0xFFDDF7F3);
  static const Color primarySoft = Color(0xFFEAF9F6);
  static const Color primaryMist = Color(0xFFF1FBF9);
  static const Color cardBackground = primarySoft;
  static const Color surfaceMuted = primarySoft;
  static const Color glass = Color(0xD9FFFFFF);
  static const Color glassStrong = Color(0xE8FFFFFF);
  static const Color glassBorder = Color(0x4DFFFFFF);
  static const Color sheetBackground = Color(0xF2FFFFFF);
  static const Color aiShellTop = Color(0xFF158F86);
  static const Color aiShellMid = Color(0xFF63D7CB);
  static const Color aiShellBottom = Color(0xFFF7F7F5);
  static const Color aiComposerFill = Color(0xEAF6FAF7);
  static const Color aiComposerBorder = Color(0x66CDEEE8);
  static const Color aiBubbleFill = Color(0xF3FFFFFF);
  static const Color aiBubbleUser = Color(0xE1F5F2F0);
  static const Color aiLine = Color(0x26FFFFFF);

  static const Color text = Color(0xFF1F2933);
  static const Color textSecondary = Color(0xFF56616A);
  static const Color textMuted = Color(0xFF7E8A94);
  static const Color border = Color(0xFFE3E8E5);

  static const Color success = primaryDark;
  static const Color successDark = primaryDeep;
  static const Color warning = Color(0xFF71808A);
  static const Color error = Color(0xFFB95864);

  static const double cornerRadius = 26;
  static const double cornerRadiusSmall = 22;
  static const double cornerRadiusLarge = 34;
  static const double fieldRadius = 28;
  static const double pillRadius = 999;

  static const LinearGradient primaryGlowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34D7C8), Color(0xFF159C92)],
  );

  static const LinearGradient whiteGlowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF1FFFD)],
  );

  static const LinearGradient aiShellGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, 0.38, 0.78, 1],
    colors: [aiShellTop, aiShellMid, Color(0xFFE9F8F5), aiShellBottom],
  );

  static const RadialGradient aiOrbGradient = RadialGradient(
    center: Alignment(0, -0.1),
    radius: 0.88,
    colors: [Color(0xFFFFFCF2), Color(0xFF9CE8DE), Color(0xFF2EC4B6)],
    stops: [0, 0.44, 1],
  );

  static ThemeData get light {
    final baseTextTheme = GoogleFonts.manropeTextTheme();
    final textTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        color: text,
        fontWeight: FontWeight.w700,
        height: 0.96,
        letterSpacing: -1.1,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        color: text,
        fontWeight: FontWeight.w700,
        height: 0.98,
        letterSpacing: -0.9,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        color: text,
        fontWeight: FontWeight.w700,
        height: 1,
        letterSpacing: -0.7,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        color: text,
        fontWeight: FontWeight.w700,
        height: 1.04,
        letterSpacing: -0.55,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        color: text,
        fontWeight: FontWeight.w800,
        height: 1.08,
        letterSpacing: -0.4,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        color: text,
        fontWeight: FontWeight.w800,
        height: 1.14,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        color: text,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        color: text,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: text,
        fontWeight: FontWeight.w500,
        height: 1.58,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: text,
        fontWeight: FontWeight.w500,
        height: 1.54,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: textSecondary,
        fontWeight: FontWeight.w500,
        height: 1.5,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        color: text,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.05,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        color: textSecondary,
        fontWeight: FontWeight.w700,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        color: textMuted,
        fontWeight: FontWeight.w700,
      ),
    );

    final colorScheme = const ColorScheme.light().copyWith(
      primary: primary,
      onPrimary: surface,
      secondary: primaryDark,
      onSecondary: surface,
      surface: surface,
      onSurface: text,
      error: error,
      onError: surface,
      outline: border,
      outlineVariant: border,
      shadow: text.withValues(alpha: 0.08),
      surfaceContainerHighest: primarySoft,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
      dividerColor: border,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: glassStrong,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadiusLarge),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(60),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          backgroundColor: primary,
          foregroundColor: surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pillRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(60),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          foregroundColor: text,
          backgroundColor: glassStrong,
          side: BorderSide(color: primary.withValues(alpha: 0.12)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pillRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: text,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: glassStrong,
        disabledColor: primarySoft,
        selectedColor: primarySoft,
        secondarySelectedColor: primarySoft,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(pillRadius),
          side: BorderSide(color: primary.withValues(alpha: 0.1)),
        ),
        labelStyle: textTheme.labelMedium?.copyWith(color: text),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: text),
        side: BorderSide(color: primary.withValues(alpha: 0.08)),
        brightness: Brightness.light,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassStrong,
        hintStyle: textTheme.bodyMedium?.copyWith(color: textMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
        helperStyle: textTheme.bodySmall?.copyWith(color: textSecondary),
        errorStyle: textTheme.bodySmall?.copyWith(color: error),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: BorderSide(
            color: primary.withValues(alpha: 0.34),
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: BorderSide(color: error.withValues(alpha: 0.36)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: BorderSide(color: error.withValues(alpha: 0.62)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
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
          return states.contains(WidgetState.selected) ? primary : primarySoft;
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: surface,
        elevation: 0,
        extendedTextStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(pillRadius),
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 8,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
        activeTrackColor: primary,
        inactiveTrackColor: primarySoft,
        thumbColor: surface,
        overlayColor: primary.withValues(alpha: 0.12),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: primarySoft,
      ),
      dividerTheme: DividerThemeData(
        color: primary.withValues(alpha: 0.08),
        thickness: 1,
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        labelColor: text,
        unselectedLabelColor: textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static List<BoxShadow> get glassShadow => [
    BoxShadow(
      color: primaryDeep.withValues(alpha: 0.08),
      blurRadius: 46,
      offset: const Offset(0, 18),
      spreadRadius: -22,
    ),
    BoxShadow(
      color: text.withValues(alpha: 0.06),
      blurRadius: 28,
      offset: const Offset(0, 10),
      spreadRadius: -20,
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: primaryDeep.withValues(alpha: 0.12),
      blurRadius: 70,
      offset: const Offset(0, 30),
      spreadRadius: -24,
    ),
  ];

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: primaryDeep.withValues(alpha: 0.08),
      blurRadius: 32,
      offset: const Offset(0, 12),
      spreadRadius: -20,
    ),
  ];

  static List<BoxShadow> get floatingShadow => [
    BoxShadow(
      color: primaryDeep.withValues(alpha: 0.14),
      blurRadius: 64,
      offset: const Offset(0, 24),
      spreadRadius: -24,
    ),
  ];

  static List<BoxShadow> get softGlowShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.32),
      blurRadius: 30,
      offset: const Offset(0, 12),
      spreadRadius: -12,
    ),
  ];

  static List<BoxShadow> get aiOrbShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.38),
      blurRadius: 64,
      offset: const Offset(0, 12),
      spreadRadius: -8,
    ),
  ];

  static List<BoxShadow> get aiComposerShadow => [
    BoxShadow(
      color: primaryDeep.withValues(alpha: 0.1),
      blurRadius: 48,
      offset: const Offset(0, 22),
      spreadRadius: -26,
    ),
  ];

  static List<BoxShadow> get heroCardShadow => [
    BoxShadow(
      color: primaryDeep.withValues(alpha: 0.22),
      blurRadius: 90,
      offset: const Offset(0, 34),
      spreadRadius: -28,
    ),
  ];

  static List<BoxShadow> get modalShadow => [
    BoxShadow(
      color: primaryDeep.withValues(alpha: 0.14),
      blurRadius: 90,
      offset: const Offset(0, 30),
      spreadRadius: -26,
    ),
  ];

  static List<BoxShadow> get cardShadow => glassShadow;
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
