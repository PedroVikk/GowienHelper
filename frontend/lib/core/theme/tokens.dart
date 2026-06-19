import 'package:flutter/material.dart';

/// Design tokens do GoWise Helper (tema escuro, hi-fi).
/// Fonte: design_handoff_gowise/README.md.
class Gw {
  Gw._();

  // ---- Cores base ----
  static const bg = Color(0xFF0F1115);
  static const bgElevated = Color(0xFF13151A);
  static const card = Color(0xFF1E2128);
  static const cardAlt = Color(0xFF15171C);
  static const cardAlt2 = Color(0xFF181B21);
  static const border = Color(0xFF2A2E37);
  static const borderSubtle = Color(0xFF23262E);

  // ---- Texto ----
  static const textHi = Color(0xFFECEDEE);
  static const textMid = Color(0xFFC8CDD3);
  static const textLo = Color(0xFF9BA1A6);
  static const textDim = Color(0xFF6B7280);

  // ---- Acentos semânticos ----
  static const primary = Color(0xFF8B7CF6); // violeta
  static const primaryLight = Color(0xFFA78BFA);
  static const success = Color(0xFF34D399); // verde
  static const accent = Color(0xFF22D3EE); // ciano
  static const streak = Color(0xFFFBBF24); // âmbar
  static const error = Color(0xFFF87171); // vermelho

  // ---- Acentos pastel por disciplina ----
  static const calculo = Color(0xFFB6A8F2); // lavanda
  static const anatomia = Color(0xFFF2A6BE); // rosa
  static const algoritmos = Color(0xFF8FE3C4); // menta
  static const psicologia = Color(0xFF97C6F2); // azul-céu
  static const bioquimica = Color(0xFFF2DD97); // manteiga

  // ---- Gradientes ----
  static const gradBrand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );
  static const gradPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFF7C6BF0)],
  );
  static const gradXp = LinearGradient(colors: [primary, primaryLight]);
  static const gradGreen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, Color(0xFF10B981)],
  );
  static const gradAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, Color(0xFF2BB8D6)],
  );

  // ---- Espaçamento (escala 4pt) ----
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s18 = 18.0; // padding lateral de tela
  static const s24 = 24.0;

  // ---- Raios ----
  static const rPill = 999.0;
  static const rChip = 12.0;
  static const rCard = 18.0;
  static const rCardLg = 24.0;
  static const rHero = 28.0;
  static const rBtn = 15.0;

  // ---- Sombras / glow ----
  static List<BoxShadow> cardShadow = const [
    BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  /// Glow neon (assinatura do app): brilho da própria cor.
  static List<BoxShadow> glow(Color c, {double alpha = 0.4, double blur = 24}) =>
      [BoxShadow(color: c.withValues(alpha: alpha), blurRadius: blur, offset: const Offset(0, 8))];

  static List<BoxShadow> softGlow(Color c, {double alpha = 0.55, double blur = 10}) =>
      [BoxShadow(color: c.withValues(alpha: alpha), blurRadius: blur)];
}
