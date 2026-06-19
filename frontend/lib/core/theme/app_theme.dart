import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Tema Material 3 escuro com tipografia Inter, derivado dos tokens.
class AppTheme {
  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Gw.bg,
      colorScheme: const ColorScheme.dark(
        surface: Gw.bg,
        primary: Gw.primary,
        secondary: Gw.accent,
        error: Gw.error,
        onPrimary: Gw.bg,
        onSurface: Gw.textHi,
      ),
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: Gw.textHi,
      displayColor: Gw.textHi,
    );

    return base.copyWith(
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      dividerColor: Gw.border,
      iconTheme: const IconThemeData(color: Gw.textLo, size: 20),
    );
  }

  // ---- Estilos de texto reutilizáveis ----
  static TextStyle overline(Color c) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: c,
      );

  static TextStyle screenTitle = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    color: Gw.textHi,
  );

  static TextStyle bigNumber(Color c, {double size = 26}) => GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 1,
        letterSpacing: -1,
        color: c,
      );

  static TextStyle label = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Gw.textLo,
  );

  static TextStyle buttonCaps = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.4,
    color: Gw.bg,
  );
}
