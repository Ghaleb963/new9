import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  AppTheme._();

  static const Color bgDeep      = Color(0xFF0D0D0D);
  static const Color bgPage      = Color(0xFF111111);
  static const Color bgSurface   = Color(0xFF1C1C1E);
  static const Color bgRaised    = Color(0xFF242426);
  static const Color bgInput     = Color(0xFF1A1A1C);

  static const Color borderSubtle = Color(0xFF2C2C2E);
  static const Color borderMedium = Color(0xFF38383A);
  static const Color borderFocus  = Color(0xFF30D158);

  static const Color accentGreen     = Color(0xFF30D158);
  static const Color accentGreenDark = Color(0xFF248A3D);
  static const Color accentGreenGlow = Color(0xFF5CE37C);

  static const Color accentAmber     = Color(0xFFFF9F0A);
  static const Color accentAmberDim  = Color(0xFFCC7A00);

  static const Color accentRed       = Color(0xFFFF453A);
  static const Color accentRedDim    = Color(0xFFCC332D);
  static const Color accentBlue      = Color(0xFF0A84FF);
  static const Color accentTeal      = Color(0xFF30B0C7);

  static const Color textHigh   = Color(0xFFF5F5F7);
  static const Color textMedium = Color(0xFF98989D);
  static const Color textLow    = Color(0xFF636366);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  static const Color darkGrey     = bgPage;
  static const Color emeraldGreen = accentGreen;
  static const Color surfaceColor = bgSurface;
  static const Color textColor    = textHigh;

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

  static const double radiusSm  = 8.0;
  static const double radiusMd  = 12.0;
  static const double radiusLg  = 16.0;
  static const double radiusXl  = 20.0;
  static const double radiusFull = 100.0;

  static const double fontXs  = 11.0;
  static const double fontSm  = 13.0;
  static const double fontMd  = 15.0;
  static const double fontLg  = 17.0;
  static const double fontXl  = 20.0;
  static const double font2xl = 24.0;

  static const FontWeight w400 = FontWeight.w400;
  static const FontWeight w500 = FontWeight.w500;
  static const FontWeight w600 = FontWeight.w600;
  static const FontWeight w700 = FontWeight.w700;
  static const FontWeight w800 = FontWeight.w800;

  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ];

  static List<BoxShadow> get shadowGreen => [
        BoxShadow(
          color: accentGreen.withValues(alpha: 0.2),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: accentGreen,
      scaffoldBackgroundColor: bgPage,
      cardColor: bgSurface,
      splashColor: accentGreen.withValues(alpha: 0.08),
      highlightColor: accentGreen.withValues(alpha: 0.04),

      colorScheme: const ColorScheme.dark(
        primary:          accentGreen,
        primaryContainer: Color(0xFF1A3A2A),
        secondary:        accentAmber,
        surface:          bgSurface,
        onSurface:        textHigh,
        onPrimary:        textOnAccent,
        error:            accentRed,
        outline:          borderMedium,
        outlineVariant:   borderSubtle,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: bgPage,
        foregroundColor: textHigh,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: textHigh,
          fontSize: fontXl,
          fontWeight: w700,
          letterSpacing: 0,
        ),
        iconTheme: IconThemeData(color: textHigh, size: 22),
        actionsIconTheme: IconThemeData(color: textMedium, size: 22),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgSurface,
        selectedItemColor: accentGreen,
        unselectedItemColor: textLow,
        selectedLabelStyle: TextStyle(
          fontSize: fontXs,
          fontWeight: w600,
        ),
        unselectedLabelStyle: TextStyle(fontSize: fontXs),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        color: bgSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: borderSubtle, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGreen,
          foregroundColor: textOnAccent,
          disabledBackgroundColor: borderMedium,
          disabledForegroundColor: textLow,
          minimumSize: const Size(double.infinity, 50),
          padding: const EdgeInsets.symmetric(horizontal: sp24, vertical: sp14),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: fontMd,
            fontWeight: w700,
            letterSpacing: 0,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentGreen,
          textStyle: const TextStyle(
            fontSize: fontSm,
            fontWeight: w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),

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
          borderSide: const BorderSide(color: borderSubtle, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: borderSubtle, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: accentGreen, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: accentRed, width: 0.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: accentRed, width: 1),
        ),
        prefixIconColor: textLow,
        suffixIconColor: textLow,
      ),

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

      dividerTheme: const DividerThemeData(
        color: borderSubtle,
        thickness: 0.5,
        space: sp24,
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: sp16, vertical: sp4),
        minVerticalPadding: sp8,
        iconColor: textMedium,
        textColor: textHigh,
      ),

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

      dialogTheme: DialogThemeData(
        backgroundColor: bgRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          side: const BorderSide(color: borderMedium, width: 0.5),
        ),
        titleTextStyle: const TextStyle(
          color: textHigh,
          fontSize: fontLg,
          fontWeight: w700,
        ),
        contentTextStyle: const TextStyle(
          color: textMedium,
          fontSize: fontMd,
          height: 1.5,
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentGreen,
        foregroundColor: textOnAccent,
        elevation: 0,
        shape: StadiumBorder(),
      ),

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

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentGreen;
          return textLow;
        }),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgRaised,
        contentTextStyle: const TextStyle(color: textHigh, fontSize: fontSm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: borderMedium, width: 0.5),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      textTheme: const TextTheme(
        displayLarge:  TextStyle(color: textHigh,   fontWeight: w800),
        displayMedium: TextStyle(color: textHigh,   fontWeight: w700),
        displaySmall:  TextStyle(color: textHigh,   fontWeight: w700),
        headlineLarge: TextStyle(color: textHigh,   fontWeight: w700),
        headlineMedium:TextStyle(color: textHigh,   fontWeight: w600),
        headlineSmall: TextStyle(color: textHigh,   fontWeight: w600),
        titleLarge:    TextStyle(color: textHigh,   fontWeight: w600, fontSize: fontXl),
        titleMedium:   TextStyle(color: textHigh,   fontWeight: w600, fontSize: fontLg),
        titleSmall:    TextStyle(color: textMedium, fontWeight: w500, fontSize: fontMd),
        bodyLarge:     TextStyle(color: textHigh,   fontSize: fontMd, height: 1.5),
        bodyMedium:    TextStyle(color: textMedium, fontSize: fontSm, height: 1.4),
        bodySmall:     TextStyle(color: textLow,    fontSize: fontXs, height: 1.3),
        labelLarge:    TextStyle(color: textHigh,   fontWeight: w600, fontSize: fontSm),
        labelMedium:   TextStyle(color: textMedium, fontSize: fontXs),
        labelSmall:    TextStyle(color: textLow,    fontSize: 10),
      ),
    );
  }
}
