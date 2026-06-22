import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/tokens.dart';

/// Barra inferior de 5 abas com FAB central "Revisar" elevado (gradiente).
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onReview;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Gw.bgElevated,
        border: Border(top: BorderSide(color: Gw.borderSubtle)),
      ),
      // SafeArea cuida do inset inferior (gesture bar). O SizedBox com altura
      // fixa é essencial: como bottomNavigationBar o Scaffold passa restrições
      // de altura frouxas, e sem limite o Center do FAB esticaria a barra até a
      // tela inteira (empurrando os ícones pro meio e zerando o corpo).
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _item(0, Icons.home_rounded, 'Início'),
              _item(1, Icons.menu_book_rounded, 'Disciplinas'),
              _fab(),
              _item(2, Icons.bar_chart_rounded, 'Stats'),
              _item(3, Icons.person_rounded, 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int index, IconData icon, String label) {
    final active = currentIndex == index;
    final color = active ? Gw.primary : Gw.textDim;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fab() {
    return Expanded(
      child: GestureDetector(
        onTap: onReview,
        child: Center(
          child: Transform.translate(
            offset: const Offset(0, -6),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: Gw.gradBrand,
                shape: BoxShape.circle,
                boxShadow: Gw.glow(Gw.primary, blur: 18, alpha: 0.5),
              ),
              child: const Icon(Icons.repeat_rounded, color: Gw.bg, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
