import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../data/mock_data.dart';
import '../../shared/widgets/common.dart';

/// Mecânica de quiz interativa (compartilhada por Quiz e Quiz por tema):
/// seleção única e irreversível por questão, feedback de cor + explicação,
/// botão "Próxima" que avança e reseta a seleção.
class QuizPlayer extends StatefulWidget {
  final List<QuizQuestion> questions;
  final Color accent;
  const QuizPlayer({super.key, required this.questions, this.accent = Gw.accent});

  @override
  State<QuizPlayer> createState() => _QuizPlayerState();
}

class _QuizPlayerState extends State<QuizPlayer> {
  int _idx = 0;
  int? _sel;

  QuizQuestion get _q => widget.questions[_idx];
  bool get _answered => _sel != null;

  void _select(int i) {
    if (_answered) return;
    setState(() => _sel = i);
  }

  void _next() {
    setState(() {
      _idx = (_idx + 1) % widget.questions.length;
      _sel = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Gw.s18, Gw.s8, Gw.s18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_idx + 1}/${widget.questions.length}',
                  style: const TextStyle(fontSize: 12, color: Gw.textLo)),
              const SizedBox(height: 8),
              GwProgressBar(
                value: (_idx + 1) / widget.questions.length,
                gradient: LinearGradient(colors: [widget.accent, widget.accent]),
                glowColor: widget.accent,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Gw.s18, Gw.s24, Gw.s18, Gw.s16),
            children: [
              Text(_q.prompt,
                  style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: Gw.textHi)),
              const SizedBox(height: Gw.s24),
              ...List.generate(_q.options.length, (i) => _option(i)),
              if (_answered) ...[
                const SizedBox(height: Gw.s8),
                _explanation(),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Gw.s18, 0, Gw.s18, Gw.s16),
          child: _answered
              ? GlowButton(
                  label: 'Próxima',
                  icon: Icons.arrow_forward_rounded,
                  gradient: Gw.gradAccent,
                  glowColor: Gw.accent,
                  onTap: _next,
                )
              : const Text('Escolha uma alternativa para continuar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Gw.textDim)),
        ),
      ],
    );
  }

  Widget _option(int i) {
    final isCorrect = i == _q.correct;
    final isSelected = i == _sel;

    Color bg = Gw.card;
    Color borderC = Gw.border;
    double opacity = 1;
    Widget? trailing;

    if (_answered) {
      if (isCorrect) {
        bg = Gw.success.withValues(alpha: 0.14);
        borderC = Gw.success;
        trailing = const Icon(Icons.check_rounded, color: Gw.success, size: 20);
      } else if (isSelected) {
        bg = Gw.error.withValues(alpha: 0.14);
        borderC = Gw.error;
        trailing = const Icon(Icons.close_rounded, color: Gw.error, size: 20);
      } else {
        opacity = 0.45;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: Gw.s12),
      child: Opacity(
        opacity: opacity,
        child: GestureDetector(
          onTap: () => _select(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(Gw.rCard),
              border: Border.all(color: borderC),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Gw.bgElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(String.fromCharCode(65 + i),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Gw.textLo)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_q.options[i],
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Gw.textHi)),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _explanation() {
    final correct = _sel == _q.correct;
    final color = correct ? Gw.success : Gw.error;
    final title = correct
        ? 'Correto! +10 XP'
        : 'Resposta: ${String.fromCharCode(65 + _q.correct)}) ${_q.options[_q.correct]}';
    return Container(
      padding: const EdgeInsets.all(Gw.s16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Gw.rCard),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(correct ? Icons.check_circle_rounded : Icons.info_rounded,
                  color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_q.explanation,
              style: const TextStyle(
                  fontSize: 13, height: 1.5, color: Gw.textMid)),
        ],
      ),
    );
  }
}
