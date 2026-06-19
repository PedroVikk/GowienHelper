import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/progress_ring.dart';

/// Tela 3 — Detalhe da disciplina (Cálculo I): hero + 4 abas interativas.
class SubjectDetailScreen extends StatefulWidget {
  const SubjectDetailScreen({super.key});

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  int _tab = 0;
  static const _accent = Gw.calculo;
  static const _tabs = ['Resumo', 'Flashcards', 'Quiz', 'Mapa'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Gw.s18, 0, Gw.s18, Gw.s24),
                children: [
                  _hero(),
                  const SizedBox(height: Gw.s16),
                  _tabBar(),
                  const SizedBox(height: Gw.s16),
                  _tabContent(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gw.s8, Gw.s8, Gw.s8, Gw.s8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Gw.textHi),
          ),
          const Expanded(
            child: Text('Cálculo I',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Gw.textHi)),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz_rounded, color: Gw.textLo),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    return GwCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_accent.withValues(alpha: 0.18), _accent.withValues(alpha: 0.04)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ProgressRing(
                size: 78,
                stroke: 8,
                progress: 0.68,
                color: _accent,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('68%',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _accent)),
                    const Text('dominado',
                        style: TextStyle(fontSize: 9, color: Gw.textLo)),
                  ],
                ),
              ),
              const SizedBox(width: Gw.s16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nível 4 · Aprendiz',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Gw.textHi)),
                    SizedBox(height: 4),
                    Text('Você está indo bem nesta matéria.',
                        style: TextStyle(fontSize: 13, color: Gw.textLo)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Gw.s16),
          const Row(
            children: [
              _HeroStat('86', 'cartões', Gw.textHi),
              _HeroStat('87%', 'precisão', Gw.success),
              _HeroStat('12', 'ofensiva', Gw.streak),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Row(
      children: List.generate(_tabs.length, (i) {
        final active = _tab == i;
        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _tab = i),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: active ? _accent : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                _tabs[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: active ? Gw.textHi : Gw.textDim,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _tabContent(BuildContext context) {
    switch (_tab) {
      case 0:
        return const _ResumoTab();
      case 1:
        return _FlashTab(onReview: () => context.push('/flashcards'));
      case 2:
        return _QuizTab(onStart: () => context.push('/quiz'));
      default:
        return const _MapaTab();
    }
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _HeroStat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Gw.textLo)),
        ],
      ),
    );
  }
}

class _ResumoTab extends StatelessWidget {
  const _ResumoTab();

  @override
  Widget build(BuildContext context) {
    return GwCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Overline('Resumo'),
          const SizedBox(height: Gw.s12),
          const Text(
            'Derivadas medem a taxa de variação instantânea de uma função. '
            'São a base para otimização, análise de movimento e construção de '
            'gráficos. Domine as regras básicas antes de partir para a regra da cadeia.',
            style: TextStyle(fontSize: 14, height: 1.55, color: Gw.textMid),
          ),
          const SizedBox(height: Gw.s16),
          ...[
            'Regra do tombo: xⁿ → n·xⁿ⁻¹',
            'Derivada de constante é 0',
            'Regra da cadeia para funções compostas',
          ].map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Gw.success, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(t,
                            style: const TextStyle(
                                fontSize: 14, color: Gw.textHi))),
                  ],
                ),
              )),
          const SizedBox(height: 4),
          const Text('Gerado de 3 PDFs · 24 páginas',
              style: TextStyle(fontSize: 12, color: Gw.textDim)),
          const SizedBox(height: Gw.s16),
          GlowButton(
            label: 'Continuar estudando',
            gradient: const LinearGradient(colors: [Gw.calculo, Gw.primary]),
            glowColor: Gw.calculo,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _FlashTab extends StatelessWidget {
  final VoidCallback onReview;
  const _FlashTab({required this.onReview});

  static const _decks = [
    ('Derivadas', '12 a revisar', Gw.calculo),
    ('Limites', 'em dia', Gw.success),
    ('Integrais', '8 a revisar', Gw.accent),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ..._decks.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: Gw.s12),
              child: GwCard(
                radius: Gw.rCard,
                padding: EdgeInsets.zero,
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 56,
                      decoration: BoxDecoration(
                        color: d.$3,
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(Gw.rCard)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.$1,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Gw.textHi)),
                          const SizedBox(height: 2),
                          Text(d.$2,
                              style:
                                  const TextStyle(fontSize: 12, color: Gw.textLo)),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: Icon(Icons.chevron_right_rounded, color: Gw.textDim),
                    ),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 4),
        GlowButton(
          label: 'Revisar 20 cartões',
          icon: Icons.repeat_rounded,
          gradient: const LinearGradient(colors: [Gw.calculo, Gw.primary]),
          glowColor: Gw.calculo,
          onTap: onReview,
        ),
      ],
    );
  }
}

class _QuizTab extends StatelessWidget {
  final VoidCallback onStart;
  const _QuizTab({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return GwCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Gw.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.bolt_rounded, color: Gw.accent),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quiz rápido · Derivadas',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Gw.textHi)),
                    SizedBox(height: 2),
                    Text('Melhor nota 87% · 3 tentativas',
                        style: TextStyle(fontSize: 12, color: Gw.textLo)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Gw.s16),
          GlowButton(
            label: 'Iniciar quiz',
            gradient: Gw.gradAccent,
            glowColor: Gw.accent,
            onTap: onStart,
          ),
        ],
      ),
    );
  }
}

class _MapaTab extends StatelessWidget {
  const _MapaTab();

  @override
  Widget build(BuildContext context) {
    return GwCard(
      child: Column(
        children: [
          _node('Derivadas', gradient: const LinearGradient(colors: [Gw.calculo, Gw.primary])),
          _connector(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _node('Regras', color: Gw.cardAlt2),
              _node('Aplicações', color: Gw.cardAlt2),
              _node('Gráficos', color: Gw.cardAlt2),
            ],
          ),
          const SizedBox(height: Gw.s16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _SubChip('Tombo'),
              _SubChip('Cadeia'),
              _SubChip('Produto'),
              _SubChip('Quociente'),
              _SubChip('Otimização'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _node(String label, {Gradient? gradient, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: gradient,
        color: color,
        borderRadius: BorderRadius.circular(Gw.rChip),
        border: gradient == null ? Border.all(color: Gw.border) : null,
        boxShadow: gradient != null ? Gw.softGlow(Gw.calculo, blur: 14, alpha: 0.35) : null,
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: gradient != null ? Gw.bg : Gw.textHi)),
    );
  }

  Widget _connector() => Container(
        width: 2,
        height: 22,
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: Gw.border,
      );
}

class _SubChip extends StatelessWidget {
  final String label;
  const _SubChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Gw.cardAlt,
        borderRadius: BorderRadius.circular(Gw.rPill),
        border: Border.all(color: Gw.borderSubtle),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 12, color: Gw.textMid)),
    );
  }
}
