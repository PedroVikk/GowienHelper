import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/progress_ring.dart';

/// Tela 1 — Dashboard. Dados reais: /stats/overview, /auth/me e /subjects.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(overviewProvider);
    final user = ref.watch(currentUserProvider);
    final subjects = ref.watch(subjectsListProvider);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: Gw.primary,
        backgroundColor: Gw.card,
        onRefresh: () async {
          ref.invalidate(overviewProvider);
          ref.invalidate(subjectsListProvider);
          ref.invalidate(currentUserProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Gw.s18, Gw.s8, Gw.s18, Gw.s24),
          children: [
            _Greeting(name: user.valueOrNull?.name ?? '...'),
            const SizedBox(height: Gw.s18),
            overview.when(
              loading: () => const _LoadingCard(height: 130),
              error: (e, _) => _ErrorCard(message: '$e'),
              data: (o) => _LevelHero(o),
            ),
            const SizedBox(height: 14),
            overview.maybeWhen(
              data: (o) => _Bento(o),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: Gw.s24),
            const Overline('Disciplinas'),
            const SizedBox(height: Gw.s12),
            subjects.when(
              loading: () => const _LoadingCard(height: 70),
              error: (e, _) => _ErrorCard(message: '$e'),
              data: (list) => list.isEmpty
                  ? _emptySubjects(context)
                  : Column(
                      children: list
                          .map((s) => _DisciplineRow(
                              s, () => context.push('/subject-studio?id=${s.id}')))
                          .toList()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptySubjects(BuildContext context) => GwCard(
        child: Column(
          children: [
            const Text('Crie sua primeira disciplina',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Gw.textHi)),
            const SizedBox(height: 4),
            const Text('Vá em Disciplinas → Nova para começar.',
                style: TextStyle(fontSize: 13, color: Gw.textLo)),
          ],
        ),
      );
}

class _Greeting extends StatelessWidget {
  final String name;
  const _Greeting({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
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
          child: Text(initial,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: Gw.bg)),
        ),
        const SizedBox(width: Gw.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Olá, $name',
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
      ],
    );
  }
}

class _LevelHero extends StatelessWidget {
  final Overview o;
  const _LevelHero(this.o);

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
            progress: o.levelProgress,
            color: Gw.primary,
            center: Container(
              width: 66,
              height: 66,
              decoration: const BoxDecoration(
                  color: Gw.bgElevated, shape: BoxShape.circle),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('NÍVEL',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: Gw.textLo)),
                  Text('${o.level}',
                      style: const TextStyle(
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
                    Text('${o.streak}',
                        style: const TextStyle(
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
                GwProgressBar(value: o.levelProgress),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${o.xp} XP',
                        style: const TextStyle(fontSize: 11, color: Gw.textLo)),
                    Text('faltam ${o.xpToNextLevel} p/ Nv ${o.level + 1}',
                        style: const TextStyle(fontSize: 11, color: Gw.textLo)),
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

class _Bento extends StatelessWidget {
  final Overview o;
  const _Bento(this.o);

  String get _time {
    final min = o.timeStudiedSeconds ~/ 60;
    if (min < 60) return '${min}min';
    return '${(min / 60).toStringAsFixed(1)}h';
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Gw.s12,
      crossAxisSpacing: Gw.s12,
      childAspectRatio: 1.55,
      children: [
        _BentoTile(Icons.local_fire_department_rounded, '${o.streak}', 'Ofensiva',
            Gw.streak),
        _BentoTile(Icons.bolt_rounded, '${o.xp}', 'XP total', Gw.accent),
        _BentoTile(Icons.track_changes_rounded,
            '${(o.accuracy * 100).round()}%', 'Precisão', Gw.success),
        _BentoTile(Icons.schedule_rounded, _time, 'Tempo', Gw.calculo),
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

class _DisciplineRow extends StatelessWidget {
  final Subject s;
  final VoidCallback onTap;
  const _DisciplineRow(this.s, this.onTap);

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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: s.color.withValues(alpha: 0.4)),
                ),
                child: Icon(s.icon, color: s.color, size: 22),
              ),
              const SizedBox(width: Gw.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Gw.textHi)),
                    const SizedBox(height: 2),
                    Text(s.professor ?? 'Estudar com IA',
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

class _LoadingCard extends StatelessWidget {
  final double height;
  const _LoadingCard({required this.height});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: const Center(child: CircularProgressIndicator(color: Gw.primary)),
      );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});
  @override
  Widget build(BuildContext context) => GwCard(
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Gw.error, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Sem dados: $message',
                  style: const TextStyle(fontSize: 13, color: Gw.textHi)),
            ),
          ],
        ),
      );
}
