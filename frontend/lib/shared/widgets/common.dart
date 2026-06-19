import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/tokens.dart';

/// Botão CTA com gradiente e glow neon (rótulo em CAPS).
class GlowButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Gradient gradient;
  final Color glowColor;
  final Color foreground;
  final VoidCallback? onTap;
  final double height;

  const GlowButton({
    super.key,
    required this.label,
    this.icon,
    this.gradient = Gw.gradPrimary,
    this.glowColor = Gw.primary,
    this.foreground = Gw.bg,
    this.onTap,
    this.height = 50,
  });

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: enabled ? widget.gradient : null,
            color: enabled ? null : Gw.border,
            borderRadius: BorderRadius.circular(Gw.rBtn),
            boxShadow: enabled ? Gw.glow(widget.glowColor) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 19, color: widget.foreground),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: enabled ? widget.foreground : Gw.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra de progresso fina com glow na parte preenchida.
class GwProgressBar extends StatelessWidget {
  final double value; // 0..1
  final Gradient gradient;
  final Color glowColor;
  final double height;

  const GwProgressBar({
    super.key,
    required this.value,
    this.gradient = Gw.gradXp,
    this.glowColor = Gw.primary,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Gw.rPill),
      child: Container(
        height: height,
        color: Gw.border,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(Gw.rPill),
                boxShadow: Gw.softGlow(glowColor, blur: 12, alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Card padrão (#1E2128 + borda 1px + sombra).
class GwCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final Color? color;
  final double radius;
  final Border? border;

  const GwCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Gw.s18),
    this.gradient,
    this.color,
    this.radius = Gw.rCardLg,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? (color ?? Gw.card) : null,
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: Gw.border),
        boxShadow: Gw.cardShadow,
      ),
      child: child,
    );
  }
}

/// Chip / pílula selecionável.
class GwChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback? onTap;
  final Widget? leading;

  const GwChip({
    super.key,
    required this.label,
    this.selected = false,
    this.accent = Gw.primary,
    this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.16) : Gw.card,
          borderRadius: BorderRadius.circular(Gw.rPill),
          border: Border.all(
            color: selected ? accent : Gw.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 6)],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Gw.textHi : Gw.textLo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overline (label maiúsculo com tracking).
class Overline extends StatelessWidget {
  final String text;
  final Color color;
  const Overline(this.text, {super.key, this.color = Gw.textLo});

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: color,
        ),
      );
}
