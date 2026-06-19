import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/mock_data.dart';
import '../../shared/widgets/common.dart';

/// Tela 5 — Simulado (configurar e iniciar simulado cronometrado).
class SimuladoScreen extends StatefulWidget {
  const SimuladoScreen({super.key});

  @override
  State<SimuladoScreen> createState() => _SimuladoScreenState();
}

class _SimuladoScreenState extends State<SimuladoScreen> {
  int _len = 20;
  bool _timer = true;

  static const _sizes = {10: '~15 min', 20: '~30 min', 50: '~75 min', 100: '~150 min'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Gw.s8, Gw.s8, Gw.s18, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: Gw.textHi),
                  ),
                  const Expanded(
                    child: Text('Simulado',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Gw.textHi)),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Gw.s18, Gw.s8, Gw.s18, Gw.s16),
                children: [
                  const Overline('Quantidade de questões'),
                  const SizedBox(height: Gw.s12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: Gw.s12,
                    crossAxisSpacing: Gw.s12,
                    childAspectRatio: 1.9,
                    children: _sizes.entries
                        .map((e) => _sizeTile(e.key, e.value))
                        .toList(),
                  ),
                  const SizedBox(height: Gw.s24),
                  _timerRow(),
                  const SizedBox(height: Gw.s24),
                  const Overline('Disciplinas incluídas'),
                  const SizedBox(height: Gw.s12),
                  Wrap(
                    spacing: Gw.s8,
                    runSpacing: Gw.s8,
                    children: MockData.disciplines
                        .map((d) => GwChip(
                              label: d.name,
                              selected: true,
                              accent: d.color,
                              leading: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: d.color, shape: BoxShape.circle),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: Gw.s24),
                  const Overline('Últimos simulados'),
                  const SizedBox(height: Gw.s12),
                  ...MockData.simulados.map(_historyRow),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gw.s18, Gw.s8, Gw.s18, Gw.s16),
              child: GlowButton(
                label: 'Iniciar simulado · $_len',
                icon: Icons.play_arrow_rounded,
                onTap: () => context.push('/quiz'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sizeTile(int n, String time) {
    final selected = _len == n;
    return GestureDetector(
      onTap: () => setState(() => _len = n),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(Gw.s16),
        decoration: BoxDecoration(
          color: selected ? Gw.primary.withValues(alpha: 0.16) : Gw.card,
          borderRadius: BorderRadius.circular(Gw.rCard),
          border: Border.all(
            color: selected ? Gw.primary : Gw.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$n',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: selected ? Gw.textHi : Gw.textMid)),
            const SizedBox(height: 2),
            Text('questões · $time',
                style: const TextStyle(fontSize: 12, color: Gw.textLo)),
          ],
        ),
      ),
    );
  }

  Widget _timerRow() {
    return GwCard(
      radius: Gw.rCard,
      padding: const EdgeInsets.symmetric(horizontal: Gw.s16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: Gw.textLo, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cronômetro',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Gw.textHi)),
                Text('30 min sugeridos',
                    style: TextStyle(fontSize: 12, color: Gw.textLo)),
              ],
            ),
          ),
          Switch(
            value: _timer,
            activeThumbColor: Gw.success,
            onChanged: (v) => setState(() => _timer = v),
          ),
        ],
      ),
    );
  }

  Widget _historyRow(SimuladoHistory h) {
    final color = h.score >= 8 ? Gw.success : Gw.streak;
    return Padding(
      padding: const EdgeInsets.only(bottom: Gw.s12),
      child: GwCard(
        radius: Gw.rCard,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Gw.textHi)),
                  const SizedBox(height: 2),
                  Text(h.date,
                      style: const TextStyle(fontSize: 12, color: Gw.textLo)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(Gw.rPill),
              ),
              child: Text(h.score.toStringAsFixed(1),
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}
