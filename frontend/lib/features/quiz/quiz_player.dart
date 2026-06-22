import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../shared/widgets/common.dart';

/// Argumentos do player (passados via go_router `extra`).
class QuizArgs {
  final String title;
  final Color accent;
  final List<Question> questions;

  /// Envia as respostas ao backend (stats/XP). Sempre true quando há gabarito
  /// no servidor (simulado), opcional para quiz salvo.
  final bool submit;

  const QuizArgs({
    required this.title,
    required this.questions,
    this.accent = Gw.accent,
    this.submit = false,
  });
}

/// Tela de quiz reutilizável (Quiz do material, Quiz por tema e Simulado).
/// Avalia localmente quando a questão traz `correctAnswer`; caso contrário
/// (simulado), envia ao servidor e usa a correção retornada.
class QuizPlayerScreen extends ConsumerStatefulWidget {
  final QuizArgs args;
  const QuizPlayerScreen({super.key, required this.args});

  @override
  ConsumerState<QuizPlayerScreen> createState() => _QuizPlayerScreenState();
}

class _QuizPlayerScreenState extends ConsumerState<QuizPlayerScreen> {
  int _idx = 0;
  int? _selected;
  bool _answered = false;
  bool _loading = false;
  bool _isCorrect = false;
  String _feedback = '';
  int _correct = 0;
  bool _finished = false;

  List<Question> get _questions => widget.args.questions;
  Question get _q => _questions[_idx];

  Future<void> _select(int i) async {
    if (_answered || _loading) return;
    final option = _q.options[i];
    final hasLocalAnswer = _q.correctAnswer.trim().isNotEmpty;

    if (hasLocalAnswer) {
      final correct = i == _q.correctIndex;
      setState(() {
        _selected = i;
        _answered = true;
        _isCorrect = correct;
        _feedback = _q.explanation;
        if (correct) _correct++;
      });
      // registra no backend (stats/XP) quando a questão é persistida
      if (widget.args.submit && _q.id != null) {
        ref
            .read(studyRepositoryProvider)
            .answer(_q.id!, option)
            .catchError((_) => (isCorrect: false, feedback: ''));
      }
    } else {
      // simulado: correção no servidor
      if (_q.id == null) return;
      setState(() {
        _selected = i;
        _loading = true;
      });
      try {
        final r = await ref.read(studyRepositoryProvider).answer(_q.id!, option);
        if (!mounted) return;
        setState(() {
          _answered = true;
          _loading = false;
          _isCorrect = r.isCorrect;
          _feedback = r.feedback;
          if (r.isCorrect) _correct++;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _selected = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao corrigir: $e'),
            backgroundColor: Gw.card,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _next() {
    if (_idx + 1 >= _questions.length) {
      setState(() => _finished = true);
    } else {
      setState(() {
        _idx++;
        _selected = null;
        _answered = false;
        _isCorrect = false;
        _feedback = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.args.accent;
    return Scaffold(
      body: SafeArea(
        child: _finished ? _scoreView() : _playView(accent),
      ),
    );
  }

  Widget _playView(Color accent) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Gw.s8, Gw.s8, Gw.s18, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close_rounded, color: Gw.textHi),
              ),
              Expanded(
                child: Text(widget.args.title,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Gw.textHi)),
              ),
              const SizedBox(width: 44),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Gw.s18, Gw.s8, Gw.s18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_idx + 1}/${_questions.length}',
                  style: const TextStyle(fontSize: 12, color: Gw.textLo)),
              const SizedBox(height: 8),
              GwProgressBar(
                value: (_idx + 1) / _questions.length,
                gradient: LinearGradient(colors: [accent, accent]),
                glowColor: accent,
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
              if (_answered && _feedback.isNotEmpty) ...[
                const SizedBox(height: Gw.s8),
                _explanation(),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Gw.s18, 0, Gw.s18, Gw.s16),
          child: _loading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(color: Gw.accent),
                  ),
                )
              : _answered
                  ? GlowButton(
                      label: _idx + 1 >= _questions.length
                          ? 'Ver resultado'
                          : 'Próxima',
                      icon: Icons.arrow_forward_rounded,
                      gradient: Gw.gradAccent,
                      glowColor: Gw.accent,
                      onTap: _next,
                    )
                  : const Text('Escolha uma alternativa',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Gw.textDim)),
        ),
      ],
    );
  }

  Widget _option(int i) {
    final hasLocalAnswer = _q.correctAnswer.trim().isNotEmpty;
    final isSelected = i == _selected;
    final isCorrectOption = hasLocalAnswer && i == _q.correctIndex;

    Color bg = Gw.card;
    Color borderC = Gw.border;
    double opacity = 1;
    Widget? trailing;

    if (_answered) {
      if (isCorrectOption) {
        bg = Gw.success.withValues(alpha: 0.14);
        borderC = Gw.success;
        trailing = const Icon(Icons.check_rounded, color: Gw.success, size: 20);
      } else if (isSelected && _isCorrect) {
        bg = Gw.success.withValues(alpha: 0.14);
        borderC = Gw.success;
        trailing = const Icon(Icons.check_rounded, color: Gw.success, size: 20);
      } else if (isSelected && !_isCorrect) {
        bg = Gw.error.withValues(alpha: 0.14);
        borderC = Gw.error;
        trailing = const Icon(Icons.close_rounded, color: Gw.error, size: 20);
      } else {
        opacity = 0.45;
      }
    } else if (isSelected) {
      borderC = Gw.accent;
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
    final color = _isCorrect ? Gw.success : Gw.error;
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
              Icon(_isCorrect ? Icons.check_circle_rounded : Icons.info_rounded,
                  color: color, size: 18),
              const SizedBox(width: 8),
              Text(_isCorrect ? 'Correto! +10 XP' : 'Incorreto',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_feedback,
              style: const TextStyle(
                  fontSize: 13, height: 1.5, color: Gw.textMid)),
        ],
      ),
    );
  }

  Widget _scoreView() {
    final total = _questions.length;
    final pct = total == 0 ? 0 : (_correct / total * 100).round();
    final color = pct >= 70 ? Gw.success : (pct >= 40 ? Gw.streak : Gw.error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gw.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              pct >= 70 ? Icons.emoji_events_rounded : Icons.flag_rounded,
              color: color,
              size: 52,
            ),
            const SizedBox(height: Gw.s16),
            Text('$_correct / $total',
                style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: Gw.textHi)),
            Text('$pct% de acerto',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: Gw.s24),
            GlowButton(
              label: 'Concluir',
              icon: Icons.check_rounded,
              onTap: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}
