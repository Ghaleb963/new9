import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ════════════════════════════════════════════════════════════════
// AppTheme — نظام التصميم الموحد "Desert Night Premium"
//
// الفلسفة:
//  • خلفية كحلية عميقة (ليست سوداء) → أكثر دفئاً ومهنية
//  • أخضر زمردي مضيء للعناصر التفاعلية → ثقة + نمو
//  • أبيض فضي للنصوص → يُقلل إجهاد العين في الاستخدام الطويل
//  • شبكة 8pt صارمة لكل المسافات والأحجام
//  • تباين عالٍ لضمان القراءة تحت ضوء الشمس
// ════════════════════════════════════════════════════════════════
class AppTheme {
  AppTheme._(); // prevent instantiation

  // ── Semantic Color Tokens ─────────────────────────────────────────────────
  // Background hierarchy — تدرج من الأعمق للأخف
  static const Color bgDeep      = Color(0xFF060B14); // أعمق طبقة (drawer/modal scrim)
  static const Color bgPage      = Color(0xFF0A0F1E); // خلفية الصفحة الرئيسية
  static const Color bgSurface   = Color(0xFF0F1829); // بطاقات وأسطح
  static const Color bgRaised    = Color(0xFF172035); // عناصر مرتفعة (nested cards)
  static const Color bgInput     = Color(0xFF0D1626); // حقول الإدخال

  // Borders & dividers
  static const Color borderSubtle = Color(0xFF1A2840); // فواصل خفية
  static const Color borderMedium = Color(0xFF223354); // حدود عادية
  static const Color borderFocus  = Color(0xFF10B981); // حدود التركيز

  // Brand accent — green (trust, growth, real estate)
  static const Color accentGreen     = Color(0xFF10B981); // أخضر زمردي مضيء
  static const Color accentGreenDark = Color(0xFF059669); // حالة الضغط
  static const Color accentGreenGlow = Color(0xFF34D399); // تمييزات خاصة

  // Secondary accent — amber (requirements/طلبات)
  static const Color accentAmber     = Color(0xFFF59E0B);
  static const Color accentAmberDim  = Color(0xFFD97706);

  // Semantic accents
  static const Color accentRed       = Color(0xFFEF4444); // خطر/حذف
  static const Color accentRedDim    = Color(0xFFDC2626);
  static const Color accentBlue      = Color(0xFF3B82F6); // معلومات
  static const Color accentTeal      = Color(0xFF14B8A6); // متاح

  // Text scale — 4 مستويات لتسلسل بصري واضح
  static const Color textHigh   = Color(0xFFF1F5F9); // عناوين + نصوص رئيسية
  static const Color textMedium = Color(0xFF8EA3C8); // نصوص ثانوية
  static const Color textLow    = Color(0xFF4A5E7E); // placeholder / muted
  static const Color textOnAccent = Color(0xFFFFFFFF); // نص على أزرار ملوّنة

  // ── Legacy aliases for backward compatibility ──────────────────────────────
  static const Color darkGrey     = bgPage;
  static const Color emeraldGreen = accentGreen;
  static const Color surfaceColor = bgSurface;
  static const Color textColor    = textHigh;

  // ── Spacing (8pt Grid) ─────────────────────────────────────────────────────
  static const double sp2  = 2.0;
  static const double sp4  = 4.0;
  static const double sp8  = 8.0;
  static const double sp10 = 10.0;
  static const double sp12 = 12.0;
  static const double sp14 = 14.0;
  static const double sp16 = 16.0;
  static const double sp20 = 20.0;
  static const double sp24 = 24.0;
  static const double sp32 = 32.0;
  static const double sp40 = 40.0;
  static const double sp48 = 48.0;

  // ── Border Radius ─────────────────────────────────────────────────────────
  static const double radiusSm  = 8.0;
  static const double radiusMd  = 12.0;
  static const double radiusLg  = 16.0;
  static const double radiusXl  = 20.0;
  static const double radiusFull = 100.0;

  // ── Typography Scale ──────────────────────────────────────────────────────
  static const double fontXs  = 11.0;
  static const double fontSm  = 13.0;
  static const double fontMd  = 15.0;
  static const double fontLg  = 17.0;
  static const double fontXl  = 20.0;
  static const double font2xl = 24.0;

  // ── Elevation / Shadow ────────────────────────────────────────────────────
  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowGreen => [
        BoxShadow(
          color: accentGreen.withValues(alpha: 0.25),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  // ── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: accentGreen,
      scaffoldBackgroundColor: bgPage,
      cardColor: bgSurface,
      splashColor: accentGreen.withValues(alpha: 0.08),
      highlightColor: accentGreen.withValues(alpha: 0.05),

      // ── Color Scheme ──────────────────────────────────────────────────────
      colorScheme: const ColorScheme.dark(
        primary:          accentGreen,
        primaryContainer: Color(0xFF064E3B),
        secondary:        accentAmber,
        surface:          bgSurface,
        onSurface:        textHigh,
        onPrimary:        textOnAccent,
        error:            accentRed,
        outline:          borderMedium,
        outlineVariant:   borderSubtle,
      ),

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: bgPage,
        foregroundColor: textHigh,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: textHigh,
          fontSize: fontXl,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: textHigh, size: 22),
        actionsIconTheme: IconThemeData(color: textMedium, size: 22),
      ),

      // ── Bottom Navigation ─────────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgSurface,
        selectedItemColor: accentGreen,
        unselectedItemColor: textLow,
        selectedLabelStyle: TextStyle(
          fontSize: fontXs,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(fontSize: fontXs),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ── Card ─────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: bgSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Elevated Button ───────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGreen,
          foregroundColor: textOnAccent,
          disabledBackgroundColor: borderMedium,
          disabledForegroundColor: textLow,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: sp24, vertical: sp16),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: fontMd,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ── Text Button ───────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentGreen,
          textStyle: const TextStyle(
            fontSize: fontSm,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),

      // ── Input Decoration ──────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgInput,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.sp16,
          vertical: AppTheme.sp14,
        ),
        hintStyle: const TextStyle(color: textLow, fontSize: fontMd),
        labelStyle: const TextStyle(color: textMedium, fontSize: fontSm),
        floatingLabelStyle: const TextStyle(color: accentGreen, fontSize: fontSm),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: borderSubtle, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: accentGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: accentRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: accentRed, width: 1.5),
        ),
        prefixIconColor: textLow,
        suffixIconColor: textLow,
      ),

      // ── Chip ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: bgRaised,
        selectedColor: accentGreen.withValues(alpha: 0.15),
        secondarySelectedColor: accentGreen.withValues(alpha: 0.15),
        disabledColor: borderSubtle,
        padding: const EdgeInsets.symmetric(horizontal: sp12, vertical: sp4),
        labelStyle: const TextStyle(color: textMedium, fontSize: fontSm),
        secondaryLabelStyle: const TextStyle(color: accentGreen, fontSize: fontSm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
          side: const BorderSide(color: borderMedium),
        ),
        showCheckmark: false,
        elevation: 0,
        pressElevation: 0,
        side: const BorderSide(color: borderMedium),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: borderSubtle,
        thickness: 1,
        space: sp24,
      ),

      // ── List Tile ─────────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: sp16, vertical: sp4),
        minVerticalPadding: sp8,
        iconColor: textMedium,
        textColor: textHigh,
      ),

      // ── Bottom Sheet ──────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: bgSurface,
        modalBackgroundColor: bgSurface,
        modalBarrierColor: Color(0xCC000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
        elevation: 0,
        dragHandleColor: borderMedium,
      ),

      // ── Dialog ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: bgRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          side: const BorderSide(color: borderMedium),
        ),
        titleTextStyle: const TextStyle(
          color: textHigh,
          fontSize: fontLg,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(
          color: textMedium,
          fontSize: fontMd,
          height: 1.6,
        ),
      ),

      // ── Floating Action Button ────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentGreen,
        foregroundColor: textOnAccent,
        elevation: 0,
        shape: StadiumBorder(),
      ),

      // ── Checkbox ─────────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentGreen;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(textOnAccent),
        side: const BorderSide(color: borderMedium, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // ── Radio ─────────────────────────────────────────────────────────────
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentGreen;
          return textLow;
        }),
      ),

      // ── Snack Bar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgRaised,
        contentTextStyle: const TextStyle(color: textHigh, fontSize: fontSm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: borderMedium),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // ── Text Theme ────────────────────────────────────────────────────────
      textTheme: const TextTheme(
        displayLarge:  TextStyle(color: textHigh,   fontWeight: FontWeight.w800),
        displayMedium: TextStyle(color: textHigh,   fontWeight: FontWeight.w700),
        displaySmall:  TextStyle(color: textHigh,   fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(color: textHigh,   fontWeight: FontWeight.w700),
        headlineMedium:TextStyle(color: textHigh,   fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: textHigh,   fontWeight: FontWeight.w600),
        titleLarge:    TextStyle(color: textHigh,   fontWeight: FontWeight.w600, fontSize: fontXl),
        titleMedium:   TextStyle(color: textHigh,   fontWeight: FontWeight.w600, fontSize: fontLg),
        titleSmall:    TextStyle(color: textMedium, fontWeight: FontWeight.w500, fontSize: fontMd),
        bodyLarge:     TextStyle(color: textHigh,   fontSize: fontMd, height: 1.6),
        bodyMedium:    TextStyle(color: textMedium, fontSize: fontSm, height: 1.5),
        bodySmall:     TextStyle(color: textLow,    fontSize: fontXs, height: 1.4),
        labelLarge:    TextStyle(color: textHigh,   fontWeight: FontWeight.w600, fontSize: fontSm),
        labelMedium:   TextStyle(color: textMedium, fontSize: fontXs),
        labelSmall:    TextStyle(color: textLow,    fontSize: 10),
      ),
    );
  }
}

