import 'dart:convert';

import 'package:flutter/material.dart' hide Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/tokens.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../shared/widgets/common.dart';
import '../quiz/quiz_player.dart';

/// Estúdio da disciplina: envie material (PDF/texto) e gere conteúdo com IA
/// (resumo / flashcards / quiz) a partir do material — tudo via backend real.
class SubjectStudioScreen extends ConsumerStatefulWidget {
  final int subjectId;
  const SubjectStudioScreen({super.key, required this.subjectId});

  @override
  ConsumerState<SubjectStudioScreen> createState() =>
      _SubjectStudioScreenState();
}

class _SubjectStudioScreenState extends ConsumerState<SubjectStudioScreen> {
  bool _uploading = false;

  // Estado de geração por tipo.
  bool _genSummary = false, _genCards = false, _genQuiz = false;
  Summary? _summary;
  List<Flashcard>? _cards;
  Quiz? _quiz;

  Subject? _findSubject() {
    final list = ref.watch(subjectsListProvider).valueOrNull;
    if (list == null) return null;
    for (final s in list) {
      if (s.id == widget.subjectId) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final subject = _findSubject();
    final color = subject?.color ?? Gw.primary;
    final materialsAsync = ref.watch(materialsProvider(widget.subjectId));
    final hasMaterial = (materialsAsync.valueOrNull ?? const []).isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(context, subject?.name ?? 'Disciplina'),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.fromLTRB(Gw.s18, Gw.s8, Gw.s18, Gw.s24),
                children: [
                  if (subject != null) _hero(subject),
                  const SizedBox(height: Gw.s24),
                  const Overline('Materiais'),
                  const SizedBox(height: Gw.s12),
                  materialsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(Gw.s16),
                      child: Center(
                          child: CircularProgressIndicator(color: Gw.primary)),
                    ),
                    error: (e, _) => _errorBox('$e'),
                    data: (mats) => Column(
                      children: [
                        if (mats.isEmpty) _emptyMaterials(),
                        ...mats.map((m) => _materialRow(m, color)),
                      ],
                    ),
                  ),
                  const SizedBox(height: Gw.s12),
                  _addMaterialButton(color),
                  const SizedBox(height: Gw.s24),
                  const Overline('Estudar com IA'),
                  const SizedBox(height: Gw.s4),
                  Text(
                    'A IA (${ref.watch(aiStatusProvider).valueOrNull?['active_label'] ?? '...'}) '
                    'gera o conteúdo a partir dos materiais.',
                    style: const TextStyle(fontSize: 12, color: Gw.textLo),
                  ),
                  _aiUsageBanner(),
                  const SizedBox(height: Gw.s12),
                  _summaryCard(hasMaterial),
                  const SizedBox(height: Gw.s12),
                  _cardsCard(hasMaterial),
                  const SizedBox(height: Gw.s12),
                  _quizCard(hasMaterial),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- header
  Widget _header(BuildContext context, String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gw.s8, Gw.s8, Gw.s8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Gw.textHi),
          ),
          Expanded(
            child: Text(name,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Gw.textHi)),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _hero(Subject s) {
    final days = s.examDate?.difference(DateTime.now()).inDays;
    return GwCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [s.color.withValues(alpha: 0.20), s.color.withValues(alpha: 0.04)],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: s.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: s.color.withValues(alpha: 0.5)),
            ),
            child: Icon(s.icon, color: s.color, size: 28),
          ),
          const SizedBox(width: Gw.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Gw.textHi)),
                if (s.professor != null) ...[
                  const SizedBox(height: 4),
                  Text(s.professor!,
                      style: const TextStyle(fontSize: 13, color: Gw.textLo)),
                ],
                if (days != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.event_rounded, size: 14, color: s.color),
                      const SizedBox(width: 5),
                      Text(days >= 0 ? 'Prova em $days dias' : 'Prova já passou',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: s.color)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- materials
  Widget _emptyMaterials() => Container(
        padding: const EdgeInsets.all(Gw.s16),
        decoration: BoxDecoration(
          color: Gw.card,
          borderRadius: BorderRadius.circular(Gw.rCard),
          border: Border.all(color: Gw.border),
        ),
        child: const Row(
          children: [
            Icon(Icons.folder_open_rounded, color: Gw.textDim, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text('Nenhum material. Envie um PDF/texto para a IA usar.',
                  style: TextStyle(fontSize: 13, color: Gw.textLo)),
            ),
          ],
        ),
      );

  Widget _materialRow(Material m, Color color) {
    final ok = m.status == 'extracted' || m.status == 'processed';
    return Padding(
      padding: const EdgeInsets.only(bottom: Gw.s8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Gw.s16, vertical: 12),
        decoration: BoxDecoration(
          color: Gw.card,
          borderRadius: BorderRadius.circular(Gw.rCard),
          border: Border.all(color: Gw.border),
        ),
        child: Row(
          children: [
            Icon(Icons.description_rounded, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.filename,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, color: Gw.textHi)),
                  Text(
                    ok ? '${m.textLength} caracteres extraídos' : m.status,
                    style: const TextStyle(fontSize: 11, color: Gw.textDim),
                  ),
                ],
              ),
            ),
            Icon(ok ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                color: ok ? Gw.success : Gw.streak, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _addMaterialButton(Color color) => GestureDetector(
        onTap: _uploading ? null : _uploadMaterial,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Gw.rCard),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_uploading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.2, color: Gw.primary),
                )
              else
                Icon(Icons.note_add_rounded, color: color, size: 20),
              const SizedBox(width: 8),
              Text(_uploading ? 'Enviando...' : 'Adicionar material (colar texto)',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      );

  Future<void> _uploadMaterial() async {
    final text = await _pasteSheet();
    if (text == null || text.trim().isEmpty) return;
    setState(() => _uploading = true);
    try {
      final bytes = utf8.encode(text);
      final name = 'Material ${DateTime.now().millisecondsSinceEpoch}.txt';
      await ref
          .read(materialsRepositoryProvider)
          .upload(widget.subjectId, bytes, name);
      ref.invalidate(materialsProvider(widget.subjectId));
      _snack('Material enviado e processado');
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  /// Folha para colar o conteúdo de estudo (vira um material .txt no backend).
  Future<String?> _pasteSheet() {
    final controller = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Gw.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Gw.rCardLg)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: Gw.s18,
          right: Gw.s18,
          top: Gw.s18,
          bottom: MediaQuery.of(context).viewInsets.bottom + Gw.s18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Adicionar material',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Gw.textHi)),
            const SizedBox(height: 4),
            const Text('Cole suas anotações, resumo ou texto da apostila.',
                style: TextStyle(fontSize: 12, color: Gw.textLo)),
            const SizedBox(height: Gw.s12),
            TextField(
              controller: controller,
              maxLines: 8,
              autofocus: true,
              style: const TextStyle(color: Gw.textHi, fontSize: 14),
              cursorColor: Gw.primary,
              decoration: InputDecoration(
                hintText: 'Ex.: Derivadas medem a taxa de variação...',
                hintStyle: const TextStyle(color: Gw.textDim),
                filled: true,
                fillColor: Gw.card,
                contentPadding: const EdgeInsets.all(14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Gw.rCard),
                  borderSide: const BorderSide(color: Gw.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Gw.rCard),
                  borderSide: const BorderSide(color: Gw.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: Gw.s12),
            GlowButton(
              label: 'Enviar material',
              icon: Icons.upload_rounded,
              onTap: () => Navigator.pop(context, controller.text),
            ),
            const SizedBox(height: Gw.s4),
          ],
        ),
      ),
    );
  }

  /// Aviso amigável quando a IA na nuvem (Gemini) está perto do limite grátis.
  Widget _aiUsageBanner() {
    final usage = ref.watch(aiStatusProvider).valueOrNull?['usage']
        as Map<String, dynamic>?;
    final msg = usage?['message'];
    if (msg == null) return const SizedBox(height: Gw.s12);
    final exhausted = usage?['exhausted'] == true;
    final color = exhausted ? Gw.error : Gw.streak;
    return Padding(
      padding: const EdgeInsets.only(top: Gw.s12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Gw.rChip),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(exhausted ? Icons.battery_alert_rounded : Icons.info_rounded,
                color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text('$msg',
                  style: const TextStyle(
                      fontSize: 12, height: 1.4, color: Gw.textHi)),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------- generation
  Widget _summaryCard(bool hasMaterial) {
    return _genCard(
      icon: Icons.summarize_rounded,
      title: 'Resumo',
      subtitle: 'Pontos-chave do material',
      color: Gw.calculo,
      loading: _genSummary,
      done: _summary != null,
      onGenerate: () => _generate(
        () => ref.read(generationRepositoryProvider).summary(widget.subjectId),
        (v) => _summary = v,
        (l) => _genSummary = l,
        hasMaterial,
      ),
      result: _summary == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_summary!.short.isNotEmpty ? _summary!.short : _summary!.full,
                    style: const TextStyle(
                        fontSize: 13, height: 1.5, color: Gw.textMid)),
                if (_summary!.topics.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ..._summary!.topics.take(5).map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Gw.calculo, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(t,
                                    style: const TextStyle(
                                        fontSize: 13, color: Gw.textHi))),
                          ],
                        ),
                      )),
                ],
              ],
            ),
    );
  }

  Widget _cardsCard(bool hasMaterial) {
    return _genCard(
      icon: Icons.style_rounded,
      title: 'Flashcards',
      subtitle: 'Cartões de revisão',
      color: Gw.primary,
      loading: _genCards,
      done: _cards != null,
      onGenerate: () => _generate(
        () => ref
            .read(generationRepositoryProvider)
            .flashcards(widget.subjectId, count: 10),
        (v) => _cards = v,
        (l) => _genCards = l,
        hasMaterial,
      ),
      result: _cards == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_cards!.length} flashcards gerados e salvos',
                    style: const TextStyle(fontSize: 13, color: Gw.textHi)),
                const SizedBox(height: 8),
                ..._cards!.take(3).map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• ${c.front}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, color: Gw.textMid)),
                    )),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    ref.invalidate(flashcardsProvider(widget.subjectId));
                    context.push('/flashcards?subject=${widget.subjectId}');
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.style_rounded, color: Gw.primary, size: 16),
                      SizedBox(width: 6),
                      Text('Revisar agora',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Gw.primary)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _quizCard(bool hasMaterial) {
    return _genCard(
      icon: Icons.bolt_rounded,
      title: 'Quiz',
      subtitle: 'Questões do material',
      color: Gw.accent,
      loading: _genQuiz,
      done: _quiz != null,
      onGenerate: () => _generate(
        () => ref.read(generationRepositoryProvider).quiz(widget.subjectId, count: 10),
        (v) => _quiz = v,
        (l) => _genQuiz = l,
        hasMaterial,
      ),
      result: _quiz == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_quiz!.questions.length} questões geradas e salvas',
                    style: const TextStyle(fontSize: 13, color: Gw.textHi)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    final s = _findSubject();
                    context.push('/quiz-player', extra: QuizArgs(
                      title: '${s?.name ?? 'Quiz'} · Quiz',
                      questions: _quiz!.questions,
                      submit: true,
                    ));
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.play_arrow_rounded, color: Gw.accent, size: 18),
                      SizedBox(width: 6),
                      Text('Iniciar quiz',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Gw.accent)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _genCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool loading,
    required bool done,
    required VoidCallback onGenerate,
    Widget? result,
  }) {
    return GwCard(
      radius: Gw.rCard,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: Gw.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Gw.textHi)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style:
                            const TextStyle(fontSize: 12, color: Gw.textLo)),
                  ],
                ),
              ),
              if (loading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child:
                      CircularProgressIndicator(strokeWidth: 2.4, color: color),
                )
              else
                GestureDetector(
                  onTap: onGenerate,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(Gw.rPill),
                    ),
                    child: Row(
                      children: [
                        Icon(done ? Icons.refresh_rounded : Icons.auto_awesome_rounded,
                            color: color, size: 16),
                        const SizedBox(width: 6),
                        Text(done ? 'Refazer' : 'Gerar',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: color)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (result != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Gw.cardAlt,
                borderRadius: BorderRadius.circular(Gw.rChip),
              ),
              child: result,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _generate<T>(
    Future<T> Function() call,
    void Function(T) onResult,
    void Function(bool) setLoading,
    bool hasMaterial,
  ) async {
    if (!hasMaterial) {
      _snack('Envie um material antes de gerar conteúdo.');
      return;
    }
    setState(() => setLoading(true));
    try {
      final result = await call();
      if (!mounted) return;
      setState(() => onResult(result));
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => setLoading(false));
    }
  }

  Widget _errorBox(String msg) => Container(
        padding: const EdgeInsets.all(Gw.s16),
        decoration: BoxDecoration(
          color: Gw.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Gw.rCard),
          border: Border.all(color: Gw.error.withValues(alpha: 0.3)),
        ),
        child: Text(msg, style: const TextStyle(color: Gw.textHi, fontSize: 13)),
      );

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Gw.card,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
