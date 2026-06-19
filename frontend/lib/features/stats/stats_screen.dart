import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/mock_data.dart';
import '../../shared/widgets/common.dart';

/// Tela 6 — Estatísticas (progresso semanal e domínio por disciplina).
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _week = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Gw.s18, Gw.s16, Gw.s18, Gw.s24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Estatísticas', style: AppTheme.screenTitle),
              _toggle(),
            ],
          ),
          const SizedBox(height: Gw.s16),
          const Row(
            children: [
              _Kpi('14h', 'tempo', Gw.textHi),
              SizedBox(width: Gw.s12),
              _Kpi('84%', 'precisão', Gw.success),
              SizedBox(width: Gw.s12),
              _Kpi('312', 'dominados', Gw.accent),
            ],
          ),
          const SizedBox(height: Gw.s24),
          _weekChart(),
          const SizedBox(height: Gw.s24),
          const Overline('Domínio por disciplina'),
          const SizedBox(height: Gw.s12),
          ...MockData.mastery.map(_masteryRow),
        ],
      ),
    );
  }

  Widget _toggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Gw.card,
        borderRadius: BorderRadius.circular(Gw.rPill),
        border: Border.all(color: Gw.border),
      ),
      child: Row(
        children: [
          _toggleBtn('Semana', _week, () => setState(() => _week = true)),
          _toggleBtn('Mês', !_week, () => setState(() => _week = false)),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Gw.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(Gw.rPill),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Gw.bg : Gw.textLo)),
      ),
    );
  }

  Widget _weekChart() {
    return GwCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Overline('Atividade da semana'),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Gw.success.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(Gw.rPill),
                ),
                child: const Text('+18%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Gw.success)),
              ),
            ],
          ),
          const SizedBox(height: Gw.s16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(MockData.weekBars.length, (i) {
                final highlight = i == 5; // sábado
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 120 * MockData.weekBars[i],
                          decoration: BoxDecoration(
                            gradient: highlight ? Gw.gradXp : null,
                            color: highlight ? null : Gw.border,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: highlight
                                ? Gw.softGlow(Gw.primary, blur: 12, alpha: 0.5)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(MockData.weekLabels[i],
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: highlight ? Gw.primary : Gw.textDim)),
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

  Widget _masteryRow(Discipline d) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gw.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(d.name,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Gw.textHi)),
              Text('${d.progress}%',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: d.color)),
            ],
          ),
          const SizedBox(height: 8),
          GwProgressBar(
            value: d.progress / 100,
            gradient: LinearGradient(colors: [d.color, d.color]),
            glowColor: d.color,
          ),
        ],
      ),
    );
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
            Text(value, style: AppTheme.bigNumber(color, size: 24)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12, color: Gw.textLo)),
          ],
        ),
      ),
    );
  }
}
