import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/mock_data.dart';
import '../../shared/widgets/common.dart';
import '../quiz/quiz_player.dart';

const _accent = Gw.psicologia; // azul-céu (disciplina selecionada)

/// Tela 7 — Quiz por tema ⭐ (setup -> quiz, escopo travado no tema).
class ThemedQuizScreen extends StatefulWidget {
  const ThemedQuizScreen({super.key});

  @override
  State<ThemedQuizScreen> createState() => _ThemedQuizScreenState();
}

class _ThemedQuizScreenState extends State<ThemedQuizScreen> {
  bool _generated = false;
  final _theme = TextEditingController();
  String _discipline = 'Psicologia';
  int _count = 10;
  String _difficulty = 'Médio';

  String get _themeLabel =>
      _theme.text.trim().isEmpty ? 'Teorias da personalidade' : _theme.text.trim();

  @override
  void dispose() {
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _generated ? _quizState(context) : _setupState(context),
      ),
    );
  }

  // ---------------------------------------------------------------- SETUP
  Widget _setupState(BuildContext context) {
    return Column(
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
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Gw.s18, Gw.s8, Gw.s18, Gw.s16),
            children: [
              const Overline('Disciplina'),
              const SizedBox(height: Gw.s12),
              Wrap(
                spacing: Gw.s8,
                runSpacing: Gw.s8,
                children: ['Psicologia', 'Cálculo I', 'Anatomia', 'Algoritmos']
                    .map((d) => GwChip(
                          label: d,
                          selected: _discipline == d,
                          accent: _accent,
                          onTap: () => setState(() => _discipline = d),
                        ))
                    .toList(),
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
                children: ['Fácil', 'Médio', 'Difícil']
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
            label: 'Gerar quiz',
            icon: Icons.auto_awesome_rounded,
            gradient: const LinearGradient(colors: [_accent, Gw.accent]),
            glowColor: _accent,
            onTap: () => setState(() => _generated = true),
          ),
        ),
      ],
    );
  }

  Widget _themeField() {
    return TextField(
      controller: _theme,
      onChanged: (_) => setState(() {}),
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
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, color: Gw.success, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 13, height: 1.4, color: Gw.textMid),
                children: [
                  TextSpan(text: 'As perguntas ficam '),
                  TextSpan(
                      text: 'presas a este tema',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: Gw.textHi)),
                  TextSpan(text: ' — sem fugir do assunto.'),
                ],
              ),
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

  // ----------------------------------------------------------------- QUIZ
  Widget _quizState(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Gw.s8, Gw.s8, Gw.s18, Gw.s8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _generated = false),
                icon: const Icon(Icons.arrow_back_rounded, color: Gw.textHi),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_discipline,
                        style: const TextStyle(
                            fontSize: 12, color: Gw.textLo)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.lock_rounded,
                            color: Gw.success, size: 15),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(_themeLabel,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Gw.textHi)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Expanded(
          child: QuizPlayer(
            questions: MockData.themedQuestions,
            accent: _accent,
          ),
        ),
      ],
    );
  }
}
