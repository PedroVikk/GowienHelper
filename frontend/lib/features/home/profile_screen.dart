import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/mock_data.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/progress_ring.dart';

/// Aba "Perfil" — nível, XP e conquistas (placeholder gamificado).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Gw.s18, Gw.s16, Gw.s18, Gw.s24),
        children: [
          Text('Perfil', style: AppTheme.screenTitle),
          const SizedBox(height: Gw.s16),
          GwCard(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x388B7CF6), Color(0x1A22D3EE)],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Gw.calculo, Gw.primary]),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text('M',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Gw.bg)),
                ),
                const SizedBox(width: Gw.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(MockData.studentName,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Gw.textHi)),
                      const SizedBox(height: 6),
                      const Text('Nível 7 · 1.240 XP',
                          style: TextStyle(color: Gw.textLo)),
                      const SizedBox(height: 8),
                      const GwProgressBar(value: 0.69),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gw.s24),
          const Overline('Conquistas'),
          const SizedBox(height: Gw.s12),
          Wrap(
            spacing: Gw.s12,
            runSpacing: Gw.s12,
            children: const [
              _Achievement(Icons.bolt_rounded, 'Primeiros passos', true),
              _Achievement(Icons.local_fire_department_rounded, 'Constância', true),
              _Achievement(Icons.track_changes_rounded, 'Precisão', false),
              _Achievement(Icons.workspace_premium_rounded, 'Centurião', false),
            ],
          ),
        ],
      ),
    );
  }
}

class _Achievement extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool unlocked;
  const _Achievement(this.icon, this.label, this.unlocked);

  @override
  Widget build(BuildContext context) {
    final c = unlocked ? Gw.streak : Gw.textDim;
    return SizedBox(
      width: 76,
      child: Column(
        children: [
          ProgressRing(
            size: 56,
            stroke: 4,
            progress: unlocked ? 1 : 0,
            color: c,
            glow: unlocked,
            center: Icon(icon, color: c, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  color: unlocked ? Gw.textMid : Gw.textDim)),
        ],
      ),
    );
  }
}
