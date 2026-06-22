import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../shared/widgets/common.dart';

/// Tela 2 — Revisão de flashcards (dados reais do backend, SM-2).
/// Sem [subjectId] mostra um seletor de disciplina.
class FlashcardScreen extends ConsumerStatefulWidget {
  final int? subjectId;
  const FlashcardScreen({super.key, this.subjectId});

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen> {
  int? _subjectId;

  @override
  void initState() {
    super.initState();
    _subjectId = widget.subjectId;
  }

  @override
  Widget build(BuildContext context) {
    if (_subjectId == null) return _SubjectPicker(onPick: (id) => setState(() => _subjectId = id));
    return _ReviewView(subjectId: _subjectId!);
  }
}

/// Seleciona qual disciplina revisar (quando aberto pelo botão central).
class _SubjectPicker extends ConsumerWidget {
  final void Function(int) onPick;
  const _SubjectPicker({required this.onPick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectsListProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(title: 'Revisar', onBack: () => context.pop()),
            Expanded(
              child: subjects.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator(color: Gw.primary)),
                error: (e, _) => Center(
                    child: Text('Erro: $e',
                        style: const TextStyle(color: Gw.textHi))),
                data: (list) => list.isEmpty
                    ? const Center(
                        child: Text('Crie uma disciplina primeiro.',
                            style: TextStyle(color: Gw.textLo)))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                            Gw.s18, Gw.s8, Gw.s18, Gw.s24),
                        children: [
                          const Overline('Escolha a disciplina'),
                          const SizedBox(height: Gw.s12),
                          ...list.map((s) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: Gw.s12),
                                child: GwCard(
                                  padding: const EdgeInsets.all(14),
                                  radius: Gw.rCard,
                                  child: InkWell(
                                    onTap: () => onPick(s.id),
                                    child: Row(
                                      children: [
                                        Icon(s.icon, color: s.color, size: 22),
                                        const SizedBox(width: Gw.s12),
                                        Expanded(
                                          child: Text(s.name,
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: Gw.textHi)),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pilha de cartões com flip + swipe, alimentada pela API.
class _ReviewView extends ConsumerStatefulWidget {
  final int subjectId;
  const _ReviewView({required this.subjectId});

  @override
  ConsumerState<_ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends ConsumerState<_ReviewView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip;
  int _idx = 0;
  int _remembered = 0;
  double _dragDx = 0;

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_flip.isAnimating) return;
    _flip.value < 0.5 ? _flip.forward() : _flip.reverse();
  }

  Future<void> _classify(Flashcard card, {required bool remembered}) async {
    // SM-2: lembrou bem = 5, não lembrou = 2.
    ref
        .read(flashcardsRepositoryProvider)
        .review(card.id, remembered ? 5 : 2)
        .catchError((_) {});
    setState(() {
      if (remembered) _remembered++;
      _idx++;
      _dragDx = 0;
      _flip.value = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(flashcardsProvider(widget.subjectId));
    return Scaffold(
      body: SafeArea(
        child: cardsAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: Gw.primary)),
          error: (e, _) => _ErrorState(message: '$e'),
          data: (cards) {
            if (cards.isEmpty) return _EmptyState(onBack: () => context.pop());
            if (_idx >= cards.length) {
              return _DoneState(
                total: cards.length,
                remembered: _remembered,
                onRestart: () => setState(() {
                  _idx = 0;
                  _remembered = 0;
                }),
                onExit: () => context.pop(),
              );
            }
            final card = cards[_idx];
            return Column(
              children: [
                _Header(
                  title: '${_idx + 1} / ${cards.length}',
                  onBack: () => context.pop(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Gw.s18, Gw.s8, Gw.s18, 0),
                  child: GwProgressBar(
                    value: (_idx) / cards.length,
                    gradient: Gw.gradGreen,
                    glowColor: Gw.success,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Gw.s18, vertical: Gw.s16),
                    child: _cardStack(card),
                  ),
                ),
                _controls(card),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _cardStack(Flashcard card) {
    return GestureDetector(
      onTap: _toggleFlip,
      onHorizontalDragUpdate: (d) => setState(() => _dragDx += d.delta.dx),
      onHorizontalDragEnd: (d) {
        if (_dragDx.abs() > 90) {
          _classify(card, remembered: _dragDx > 0);
        } else {
          setState(() => _dragDx = 0);
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          _bgCard(scale: 0.9, dy: 24),
          _bgCard(scale: 0.95, dy: 12),
          Transform.translate(
            offset: Offset(_dragDx, 0),
            child: Transform.rotate(
              angle: _dragDx / 1800,
              child: AnimatedBuilder(
                animation: _flip,
                builder: (context, _) {
                  final angle = _flip.value * math.pi;
                  final isBack = angle > math.pi / 2;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0008)
                      ..rotateY(angle),
                    child: isBack
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: _face('Resposta', card.back, Gw.success),
                          )
                        : _face('Pergunta', card.front, Gw.anatomia,
                            hint: true),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bgCard({required double scale, required double dy}) {
    return Transform.translate(
      offset: Offset(0, dy),
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Gw.cardAlt,
            borderRadius: BorderRadius.circular(Gw.rHero),
            border: Border.all(color: Gw.borderSubtle),
          ),
        ),
      ),
    );
  }

  Widget _face(String label, String text, Color accent, {bool hint = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Gw.s24),
      decoration: BoxDecoration(
        color: Gw.card,
        borderRadius: BorderRadius.circular(Gw.rHero),
        border: Border.all(color: Gw.border),
        boxShadow: Gw.cardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Overline(label, color: accent),
          const SizedBox(height: Gw.s24),
          Text(text,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: Gw.textHi)),
          const SizedBox(height: Gw.s24),
          if (hint)
            const Center(
              child: Text('Toque para virar',
                  style: TextStyle(fontSize: 12, color: Gw.textDim)),
            ),
        ],
      ),
    );
  }

  Widget _controls(Flashcard card) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gw.s18, 0, Gw.s18, Gw.s16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GlowButton(
                  label: 'Não lembrei',
                  icon: Icons.refresh_rounded,
                  gradient: const LinearGradient(
                      colors: [Gw.error, Color(0xFFE0555A)]),
                  glowColor: Gw.error,
                  onTap: () => _classify(card, remembered: false),
                ),
              ),
              const SizedBox(width: Gw.s12),
              Expanded(
                child: GlowButton(
                  label: 'Lembrei',
                  icon: Icons.check_rounded,
                  gradient: Gw.gradGreen,
                  glowColor: Gw.success,
                  onTap: () => _classify(card, remembered: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gw.s12),
          const Text('Arraste ← não lembrei · → lembrei',
              style: TextStyle(fontSize: 12, color: Gw.textDim)),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _Header({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gw.s12, Gw.s8, Gw.s18, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Gw.textHi),
          ),
          Expanded(
            child: Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Gw.textHi)),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onBack;
  const _EmptyState({required this.onBack});
  @override
  Widget build(BuildContext context) => Column(
        children: [
          _Header(title: 'Revisar', onBack: onBack),
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(Gw.s24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.style_rounded, color: Gw.textDim, size: 36),
                    SizedBox(height: 12),
                    Text('Nenhum flashcard ainda',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Gw.textHi)),
                    SizedBox(height: 4),
                    Text('Gere flashcards no estúdio da disciplina (com IA).',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Gw.textLo)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
}

class _DoneState extends StatelessWidget {
  final int total;
  final int remembered;
  final VoidCallback onRestart;
  final VoidCallback onExit;
  const _DoneState({
    required this.total,
    required this.remembered,
    required this.onRestart,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gw.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration_rounded, color: Gw.success, size: 48),
            const SizedBox(height: Gw.s16),
            const Text('Revisão concluída!',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Gw.textHi)),
            const SizedBox(height: 6),
            Text('Você lembrou de $remembered de $total cartões.',
                style: const TextStyle(fontSize: 14, color: Gw.textLo)),
            const SizedBox(height: Gw.s24),
            GlowButton(
                label: 'Revisar de novo',
                icon: Icons.replay_rounded,
                onTap: onRestart),
            const SizedBox(height: Gw.s12),
            GestureDetector(
              onTap: onExit,
              child: const Text('Voltar',
                  style: TextStyle(color: Gw.textLo, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(Gw.s24),
          child: Text('Não foi possível carregar: $message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Gw.textHi, fontSize: 14)),
        ),
      );
}
