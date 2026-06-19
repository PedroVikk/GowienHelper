import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/mock_data.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/progress_ring.dart';

/// Tela 1 — Dashboard (Opção A: bento gamificado, densidade alta).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Gw.s18, Gw.s8, Gw.s18, Gw.s24),
        children: [
          const _Greeting(),
          const SizedBox(height: Gw.s18),
          const _LevelHero(),
          const SizedBox(height: 14),
          _TodayReview(onReview: () => context.push('/flashcards')),
          const SizedBox(height: 14),
          const _Bento(),
          const SizedBox(height: Gw.s24),
          const Overline('Missões diárias'),
          const SizedBox(height: Gw.s12),
          ...MockData.missions.map((m) => _MissionRow(m)),
          const SizedBox(height: Gw.s24),
          const Overline('Disciplinas'),
          const SizedBox(height: Gw.s12),
          ...MockData.disciplines
              .map((d) => _DisciplineRow(d, () => context.push('/subject'))),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Gw.calculo, Gw.primary],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          alignment: Alignment.center,
          child: Text(MockData.studentName[0],
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: Gw.bg)),
        ),
        const SizedBox(width: Gw.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Olá, ${MockData.studentName}',
                  style: const TextStyle(fontSize: 13, color: Gw.textLo)),
              const Text('Bora revisar?',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: Gw.textHi)),
            ],
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Gw.card,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Gw.border),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.notifications_none_rounded,
                  size: 20, color: Gw.textLo),
              Positioned(
                top: 9,
                right: 9,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Gw.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: Gw.card, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LevelHero extends StatelessWidget {
  const _LevelHero();

  @override
  Widget build(BuildContext context) {
    return GwCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x388B7CF6), Color(0x1A22D3EE)],
      ),
      child: Row(
        children: [
          ProgressRing(
            size: 84,
            stroke: 9,
            progress: 0.69,
            color: Gw.primary,
            center: Container(
              width: 66,
              height: 66,
              decoration: const BoxDecoration(
                  color: Gw.bgElevated, shape: BoxShape.circle),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('NÍVEL',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: Gw.textLo)),
                  Text('7',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1,
                          letterSpacing: -1,
                          color: Gw.textHi)),
                ],
              ),
            ),
          ),
          const SizedBox(width: Gw.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: Gw.streak, size: 20),
                    const SizedBox(width: 7),
                    const Text('${MockData.streakDays}',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: Gw.textHi)),
                    const SizedBox(width: 6),
                    const Text('dias de ofensiva',
                        style: TextStyle(fontSize: 13, color: Gw.textLo)),
                  ],
                ),
                const SizedBox(height: 8),
                const GwProgressBar(value: 0.69),
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1.240 XP',
                        style: TextStyle(fontSize: 11, color: Gw.textLo)),
                    Text('faltam 560 p/ Nv 8',
                        style: TextStyle(fontSize: 11, color: Gw.textLo)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayReview extends StatelessWidget {
  final VoidCallback onReview;
  const _TodayReview({required this.onReview});

  @override
  Widget build(BuildContext context) {
    return GwCard(
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Revisão de hoje',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Gw.textHi)),
                    SizedBox(height: 2),
                    Text('24 cartões · 5 disciplinas · vencendo agora',
                        style: TextStyle(fontSize: 12, color: Gw.textLo)),
                  ],
                ),
              ),
              ProgressRing(
                size: 50,
                stroke: 5,
                progress: 0,
                color: Gw.accent,
                glow: false,
                center: const Text('0/24',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Gw.accent)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GlowButton(
            label: 'Revisar agora',
            icon: Icons.repeat_rounded,
            height: 48,
            onTap: onReview,
          ),
        ],
      ),
    );
  }
}

class _Bento extends StatelessWidget {
  const _Bento();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Gw.s12,
      crossAxisSpacing: Gw.s12,
      childAspectRatio: 1.55,
      children: const [
        _BentoTile(Icons.local_fire_department_rounded, '12', 'Ofensiva', Gw.streak),
        _BentoTile(Icons.bolt_rounded, '240', 'XP hoje', Gw.accent),
        _BentoTile(Icons.track_changes_rounded, '87%', 'Precisão', Gw.success),
        _BentoTile(Icons.schedule_rounded, '42min', 'Tempo hoje', Gw.calculo),
      ],
    );
  }
}

class _BentoTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _BentoTile(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return GwCard(
      radius: Gw.rCard,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTheme.bigNumber(Gw.textHi, size: 24)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Gw.textLo)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  final Mission m;
  const _MissionRow(this.m);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gw.s12),
      child: GwCard(
        radius: Gw.rCard,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Gw.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(m.icon, color: Gw.primary, size: 19),
            ),
            const SizedBox(width: Gw.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Gw.textHi)),
                  const SizedBox(height: 8),
                  GwProgressBar(value: m.done / m.total, height: 6),
                ],
              ),
            ),
            const SizedBox(width: Gw.s12),
            Text('+${m.reward} XP',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Gw.accent)),
          ],
        ),
      ),
    );
  }
}

class _DisciplineRow extends StatelessWidget {
  final Discipline d;
  final VoidCallback onTap;
  const _DisciplineRow(this.d, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gw.s12),
      child: GwCard(
        radius: Gw.rCard,
        padding: const EdgeInsets.all(14),
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              ProgressRing(
                size: 44,
                stroke: 5,
                progress: d.progress / 100,
                color: d.color,
                center: Text('${d.progress}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: d.color)),
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
                        style: const TextStyle(fontSize: 12, color: Gw.textLo)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Gw.textDim),
            ],
          ),
        ),
      ),
    );
  }
}
