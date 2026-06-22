import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../shared/widgets/common.dart';

/// Tela 6 — Estatísticas reais: /stats/overview, /evolution, /by-subject.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(overviewProvider);
    final evolution = ref.watch(evolutionProvider);
    final bySubject = ref.watch(bySubjectProvider);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: Gw.primary,
        backgroundColor: Gw.card,
        onRefresh: () async {
          ref.invalidate(overviewProvider);
          ref.invalidate(evolutionProvider);
          ref.invalidate(bySubjectProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Gw.s18, Gw.s16, Gw.s18, Gw.s24),
          children: [
            Text('Estatísticas', style: AppTheme.screenTitle),
            const SizedBox(height: Gw.s16),
            overview.when(
              loading: () => const _Loading(120),
              error: (e, _) => _ErrorCard('$e'),
              data: (o) => Row(
                children: [
                  _Kpi(_fmtTime(o.timeStudiedSeconds), 'tempo', Gw.textHi),
                  const SizedBox(width: Gw.s12),
                  _Kpi('${(o.accuracy * 100).round()}%', 'precisão', Gw.success),
                  const SizedBox(width: Gw.s12),
                  _Kpi('${o.correctAnswers}', 'acertos', Gw.accent),
                ],
              ),
            ),
            const SizedBox(height: Gw.s24),
            evolution.when(
              loading: () => const _Loading(180),
              error: (e, _) => _ErrorCard('$e'),
              data: (days) => _WeekChart(days),
            ),
            const SizedBox(height: Gw.s24),
            const Overline('Desempenho por disciplina'),
            const SizedBox(height: Gw.s12),
            bySubject.when(
              loading: () => const _Loading(80),
              error: (e, _) => _ErrorCard('$e'),
              data: (items) => items.isEmpty
                  ? const Text('Responda questões para ver seu desempenho.',
                      style: TextStyle(fontSize: 13, color: Gw.textLo))
                  : Column(children: items.map(_masteryRow).toList()),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtTime(int seconds) {
    final min = seconds ~/ 60;
    if (min < 60) return '${min}min';
    return '${(min / 60).toStringAsFixed(1)}h';
  }

  Widget _masteryRow(SubjectStat s) {
    final pct = (s.accuracy * 100).round();
    final color = s.accuracy >= 0.7
        ? Gw.success
        : (s.accuracy >= 0.4 ? Gw.streak : Gw.error);
    return Padding(
      padding: const EdgeInsets.only(bottom: Gw.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.name,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Gw.textHi)),
              Text('$pct%',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          GwProgressBar(
            value: s.accuracy,
            gradient: LinearGradient(colors: [color, color]),
            glowColor: color,
          ),
        ],
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  final List<DailyStat> days;
  const _WeekChart(this.days);

  @override
  Widget build(BuildContext context) {
    final maxVal = days.fold<int>(1, (m, d) => d.answered > m ? d.answered : m);
    return GwCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Overline('Atividade dos últimos dias'),
          const SizedBox(height: Gw.s16),
          SizedBox(
            height: 140,
            child: days.isEmpty
                ? const Center(
                    child: Text('Sem atividade ainda',
                        style: TextStyle(color: Gw.textDim, fontSize: 13)))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(days.length, (i) {
                      final d = days[i];
                      final h = 120 * (d.answered / maxVal).clamp(0.04, 1.0);
                      final highlight = i == days.length - 1;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                height: h,
                                decoration: BoxDecoration(
                                  gradient: highlight ? Gw.gradXp : null,
                                  color: highlight ? null : Gw.border,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: highlight
                                      ? Gw.softGlow(Gw.primary,
                                          blur: 12, alpha: 0.5)
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(_label(d.day),
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: highlight
                                          ? Gw.primary
                                          : Gw.textDim)),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }

  /// Pega "DD" de uma data ISO (YYYY-MM-DD).
  String _label(String day) {
    final parts = day.split('-');
    return parts.length == 3 ? parts[2] : day;
  }
}

class _Kpi extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _Kpi(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GwCard(
        radius: Gw.rCard,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTheme.bigNumber(color, size: 22)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12, color: Gw.textLo)),
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  final double height;
  const _Loading(this.height);
  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child:
            const Center(child: CircularProgressIndicator(color: Gw.primary)),
      );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard(this.message);
  @override
  Widget build(BuildContext context) => GwCard(
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Gw.error, size: 20),
            const SizedBox(width: 12),
            Expanded(
                child: Text('Sem dados: $message',
                    style: const TextStyle(fontSize: 13, color: Gw.textHi))),
          ],
        ),
      );
}
