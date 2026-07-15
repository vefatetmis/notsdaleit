import 'package:flutter/material.dart';

import 'nd_colors.dart';

/// notdaleit tasarımına göre açık/koyu Material temaları. Renkler [NdColors]
/// token'larından gelir; tipografi Instrument Sans.
class AppTheme {
  const AppTheme._();

  static const String fontFamily = 'InstrumentSans';

  static ThemeData light() => _build(Brightness.light, NdColors.light);

  static ThemeData dark() => _build(Brightness.dark, NdColors.dark);

  static ThemeData _build(Brightness brightness, NdColors nd) {
    final base = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4A6CF7),
      brightness: brightness,
    );
    final colorScheme = base.copyWith(
      primary: nd.accent,
      onPrimary: nd.accentFg,
      surface: nd.bg,
      onSurface: nd.text,
      surfaceContainerHighest: nd.card,
      outline: nd.border,
      error: const Color(0xFFE0533D),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: nd.bg,
      canvasColor: nd.bg,
      dividerColor: nd.border,
      splashFactory: InkSparkle.splashFactory,
      extensions: [nd],
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: nd.text,
        selectionColor: nd.text.withValues(alpha: 0.20),
        selectionHandleColor: nd.text2,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: nd.accent,
        contentTextStyle: TextStyle(
          color: nd.accentFg,
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: nd.card,
        surfaceTintColor: Colors.transparent,
      ),
      // Tüm açılır menüler (paylaş/içe aktar) tasarımla tutarlı: kart zemini,
      // yuvarlak köşe, ince kenarlık, tema fontu.
      popupMenuTheme: PopupMenuThemeData(
        color: nd.card,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: nd.border),
        ),
        textStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          color: nd.text,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: nd.card,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
