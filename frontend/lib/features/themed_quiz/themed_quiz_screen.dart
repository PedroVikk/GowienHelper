import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories.dart';
import '../../shared/widgets/common.dart';
import '../quiz/quiz_player.dart';

const _accent = Gw.psicologia;
const _difficulties = {'Fácil': 'easy', 'Médio': 'medium', 'Difícil': 'hard'};

/// Tela 7 — Quiz por tema: gera questões travadas em um tema (POST .../quiz/themed).
class ThemedQuizScreen extends ConsumerStatefulWidget {
  const ThemedQuizScreen({super.key});

  @override
  ConsumerState<ThemedQuizScreen> createState() => _ThemedQuizScreenState();
}

class _ThemedQuizScreenState extends ConsumerState<ThemedQuizScreen> {
  final _theme = TextEditingController();
  int? _subjectId;
  int _count = 10;
  String _difficulty = 'Médio';
  bool _loading = false;

  @override
  void dispose() {
    _theme.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final theme = _theme.text.trim();
    if (_subjectId == null || theme.isEmpty) {
      _snack('Escolha a disciplina e digite o tema.');
      return;
    }
    setState(() => _loading = true);
    try {
      final questions =
          await ref.read(generationRepositoryProvider).themedQuiz(
                _subjectId!,
                theme: theme,
                count: _count,
                difficulty: _difficulties[_difficulty]!,
              );
      if (!mounted) return;
      if (questions.isEmpty) {
        _snack('A IA não retornou questões. Tente outro tema.');
        return;
      }
      context.push('/quiz-player',
          extra: QuizArgs(
            title: theme,
            questions: questions,
            accent: _accent,
          ));
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m),
        backgroundColor: Gw.card,
        behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsListProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.fromLTRB(Gw.s18, Gw.s8, Gw.s18, Gw.s16),
                children: [
                  const Overline('Disciplina'),
                  const SizedBox(height: Gw.s12),
                  subjects.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(color: Gw.primary)),
                    error: (e, _) => Text('Erro: $e',
                        style: const TextStyle(color: Gw.textHi)),
                    data: (list) => list.isEmpty
                        ? const Text('Crie uma disciplina primeiro.',
                            style: TextStyle(fontSize: 13, color: Gw.textLo))
                        : Wrap(
                            spacing: Gw.s8,
                            runSpacing: Gw.s8,
                            children: list
                                .map((s) => GwChip(
                                      label: s.name,
                                      selected: _subjectId == s.id,
                                      accent: _accent,
                                      onTap: () =>
                                          setState(() => _subjectId = s.id),
                                    ))
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: Gw.s24),
                  const Overline('Tema'),
                  const SizedBox(height: Gw.s12),
                  _themeField(),
                  const SizedBox(height: Gw.s12),
                  _lockNotice(),
                  const SizedBox(height: Gw.s24),
                  const Overline('Nº de questões'),
                  const SizedBox(height: Gw.s12),
                  _segment([5, 10, 20]),
                  const SizedBox(height: Gw.s24),
                  const Overline('Dificuldade'),
                  const SizedBox(height: Gw.s12),
                  Wrap(
                    spacing: Gw.s8,
                    children: _difficulties.keys
                        .map((d) => GwChip(
                              label: d,
                              selected: _difficulty == d,
                              accent: _accent,
                              onTap: () => setState(() => _difficulty = d),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gw.s18, Gw.s8, Gw.s18, Gw.s16),
              child: GlowButton(
                label: _loading ? 'Gerando com IA...' : 'Gerar quiz',
                icon: Icons.auto_awesome_rounded,
                gradient: const LinearGradient(colors: [_accent, Gw.accent]),
                glowColor: _accent,
                onTap: _loading ? null : _generate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gw.s8, Gw.s8, Gw.s18, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Gw.textHi),
          ),
          const Expanded(
            child: Text('Novo quiz por tema',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Gw.textHi)),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _themeField() {
    return TextField(
      controller: _theme,
      style: const TextStyle(color: Gw.textHi, fontSize: 15),
      cursorColor: _accent,
      decoration: InputDecoration(
        hintText: 'Ex.: Teorias da personalidade',
        hintStyle: const TextStyle(color: Gw.textDim),
        prefixIcon: const Icon(Icons.tag_rounded, color: _accent, size: 20),
        filled: true,
        fillColor: Gw.card,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Gw.rCard),
          borderSide: const BorderSide(color: Gw.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Gw.rCard),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
      ),
    );
  }

  Widget _lockNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Gw.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Gw.rChip),
        border: Border.all(color: Gw.success.withValues(alpha: 0.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_rounded, color: Gw.success, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'As perguntas ficam presas a este tema — usa o material se houver, senão o conhecimento geral da IA.',
              style: TextStyle(fontSize: 13, height: 1.4, color: Gw.textMid),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment(List<int> options) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Gw.card,
        borderRadius: BorderRadius.circular(Gw.rChip),
        border: Border.all(color: Gw.border),
      ),
      child: Row(
        children: options.map((n) {
          final active = _count == n;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _count = n),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? _accent.withValues(alpha: 0.18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                      color: active ? _accent : Colors.transparent, width: 1.5),
                ),
                child: Text('$n',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: active ? Gw.textHi : Gw.textLo)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
