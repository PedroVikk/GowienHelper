import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/mock_data.dart';
import '../../shared/widgets/common.dart';

/// Tela 2 — Flashcard (Opção B: pilha + flip + swipe + dica mnemônica).
class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip;
  int _idx = 0;
  int _done = 12; // dominados
  double _dragDx = 0;

  static const _total = 30;

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  FlashcardData get _card => MockData.flashcards[_idx % MockData.flashcards.length];

  void _toggleFlip() {
    if (_flip.isAnimating) return;
    _flip.value < 0.5 ? _flip.forward() : _flip.reverse();
  }

  void _classify({required bool remembered}) {
    setState(() {
      if (remembered && _done < _total) _done++;
      _idx++;
      _dragDx = 0;
      _flip.value = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context),
            _progress(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Gw.s18, vertical: Gw.s16),
                child: _cardStack(),
              ),
            ),
            _controls(),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gw.s12, Gw.s8, Gw.s18, 0),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Gw.textHi)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Gw.streak.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Gw.rPill),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department_rounded,
                    color: Gw.streak, size: 16),
                SizedBox(width: 4),
                Text('${MockData.streakDays}',
                    style: TextStyle(
                        color: Gw.streak,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gw.s18, Gw.s8, Gw.s18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$_done/$_total dominados',
              style: const TextStyle(fontSize: 12, color: Gw.textLo)),
          const SizedBox(height: 8),
          GwProgressBar(value: _done / _total, gradient: Gw.gradGreen, glowColor: Gw.success),
        ],
      ),
    );
  }

  Widget _cardStack() {
    return GestureDetector(
      onTap: _toggleFlip,
      onHorizontalDragUpdate: (d) => setState(() => _dragDx += d.delta.dx),
      onHorizontalDragEnd: (d) {
        if (_dragDx.abs() > 90) {
          _classify(remembered: _dragDx > 0);
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
                            child: _backFace(),
                          )
                        : _frontFace(),
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

  Widget _face({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Gw.s24),
      decoration: BoxDecoration(
        color: Gw.card,
        borderRadius: BorderRadius.circular(Gw.rHero),
        border: Border.all(color: Gw.border),
        boxShadow: Gw.cardShadow,
      ),
      child: child,
    );
  }

  Widget _frontFace() {
    final c = _card;
    return _face(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Overline('Pergunta', color: Gw.anatomia),
              _masteryDots(c.mastery),
            ],
          ),
          const SizedBox(height: Gw.s24),
          Text(c.question,
              style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  color: Gw.textHi)),
          const SizedBox(height: Gw.s24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Gw.anatomia.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Gw.rChip),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    color: Gw.anatomia, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(c.hint,
                      style: const TextStyle(
                          fontSize: 13, color: Gw.textMid)),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gw.s16),
          const Center(
            child: Text('Toque para virar',
                style: TextStyle(fontSize: 12, color: Gw.textDim)),
          ),
        ],
      ),
    );
  }

  Widget _backFace() {
    final c = _card;
    return _face(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Overline('Resposta', color: Gw.success),
          const SizedBox(height: Gw.s24),
          Text(c.answer,
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: Gw.textHi)),
          const SizedBox(height: Gw.s24),
          Container(
            padding: const EdgeInsets.only(left: 12),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Gw.anatomia, width: 2)),
            ),
            child: Text(c.mnemonic,
                style: const TextStyle(
                    fontSize: 14, height: 1.5, color: Gw.textMid)),
          ),
        ],
      ),
    );
  }

  Widget _masteryDots(int filled) {
    return Row(
      children: List.generate(5, (i) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(left: 5),
          decoration: BoxDecoration(
            color: i < filled ? Gw.anatomia : Gw.border,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gw.s18, 0, Gw.s18, Gw.s16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GlowButton(
                  label: 'Revisar',
                  icon: Icons.arrow_back_rounded,
                  gradient: const LinearGradient(
                      colors: [Gw.error, Color(0xFFE0555A)]),
                  glowColor: Gw.error,
                  foreground: Gw.bg,
                  onTap: () => _classify(remembered: false),
                ),
              ),
              const SizedBox(width: Gw.s12),
              Expanded(
                child: GlowButton(
                  label: 'Lembrei',
                  icon: Icons.arrow_forward_rounded,
                  gradient: Gw.gradGreen,
                  glowColor: Gw.success,
                  onTap: () => _classify(remembered: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gw.s12),
          const Text('Arraste ← revisar depois · → já lembro',
              style: TextStyle(fontSize: 12, color: Gw.textDim)),
        ],
      ),
    );
  }
}
