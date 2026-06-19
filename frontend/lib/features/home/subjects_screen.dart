import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/mock_data.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/progress_ring.dart';

/// Aba "Disciplinas": atalhos para Simulado / Quiz por tema + lista de matérias.
class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Gw.s18, Gw.s16, Gw.s18, Gw.s24),
        children: [
          Text('Disciplinas', style: AppTheme.screenTitle),
          const SizedBox(height: Gw.s16),
          Row(
            children: [
              Expanded(
                child: GlowButton(
                  label: 'Simulado',
                  icon: Icons.timer_outlined,
                  onTap: () => context.push('/simulado'),
                ),
              ),
              const SizedBox(width: Gw.s12),
              Expanded(
                child: GlowButton(
                  label: 'Quiz por tema',
                  icon: Icons.lock_outline_rounded,
                  gradient: Gw.gradAccent,
                  glowColor: Gw.accent,
                  onTap: () => context.push('/themed-quiz'),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gw.s24),
          const Overline('Suas matérias'),
          const SizedBox(height: Gw.s12),
          ...MockData.disciplines.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: Gw.s12),
                child: GwCard(
                  padding: const EdgeInsets.all(14),
                  radius: Gw.rCard,
                  child: InkWell(
                    onTap: () => context.push('/subject'),
                    child: Row(
                      children: [
                        ProgressRing(
                          size: 46,
                          stroke: 5,
                          progress: d.progress / 100,
                          color: d.color,
                          center: Text('${d.progress}%',
                              style: AppTheme.bigNumber(d.color, size: 12)),
                        ),
                        const SizedBox(width: Gw.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.name,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Gw.textHi)),
                              const SizedBox(height: 2),
                              Text('${d.cardsToReview} cartões para revisar',
                                  style: const TextStyle(
                                      fontSize: 12, color: Gw.textLo)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: Gw.textDim),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
