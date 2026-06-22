import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories.dart';
import '../../shared/widgets/common.dart';
import '../quiz/quiz_player.dart';

/// Tela 5 — Simulado: escolhe quantidade e disciplinas e monta um simulado
/// misturando questões já geradas (POST /simulados).
class SimuladoScreen extends ConsumerStatefulWidget {
  const SimuladoScreen({super.key});

  @override
  ConsumerState<SimuladoScreen> createState() => _SimuladoScreenState();
}

class _SimuladoScreenState extends ConsumerState<SimuladoScreen> {
  int _len = 20;
  final Set<int> _selected = {};
  bool _loading = false;

  static const _sizes = {10: '~15 min', 20: '~30 min', 50: '~75 min', 100: '~150 min'};

  Future<void> _start(List<int> allIds) async {
    setState(() => _loading = true);
    try {
      final ids = _selected.isEmpty ? allIds : _selected.toList();
      final questions =
          await ref.read(studyRepositoryProvider).simulado(_len, ids);
      if (!mounted) return;
      if (questions.isEmpty) {
        _snack(
            'Nenhuma questão disponível. Gere quizzes nas disciplinas primeiro.');
        return;
      }
      context.push('/quiz-player',
          extra: QuizArgs(
            title: 'Simulado · ${questions.length}q',
            questions: questions,
            accent: Gw.primary,
            submit: true,
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
    final allIds = subjects.valueOrNull?.map((s) => s.id).toList() ?? const [];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.fromLTRB(Gw.s18, Gw.s8, Gw.s18, Gw.s16),
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
                  const Overline('Disciplinas incluídas'),
                  const SizedBox(height: Gw.s4),
                  const Text('Vazio = todas. Toque para filtrar.',
                      style: TextStyle(fontSize: 12, color: Gw.textLo)),
                  const SizedBox(height: Gw.s12),
                  subjects.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(color: Gw.primary)),
                    error: (e, _) => Text('Erro: $e',
                        style: const TextStyle(color: Gw.textHi)),
                    data: (list) => list.isEmpty
                        ? const Text('Crie disciplinas e gere quizzes primeiro.',
                            style: TextStyle(fontSize: 13, color: Gw.textLo))
                        : Wrap(
                            spacing: Gw.s8,
                            runSpacing: Gw.s8,
                            children: list.map((s) {
                              final sel = _selected.contains(s.id);
                              return GwChip(
                                label: s.name,
                                selected: sel,
                                accent: s.color,
                                leading: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                      color: s.color, shape: BoxShape.circle),
                                ),
                                onTap: () => setState(() => sel
                                    ? _selected.remove(s.id)
                                    : _selected.add(s.id)),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gw.s18, Gw.s8, Gw.s18, Gw.s16),
              child: GlowButton(
                label: _loading ? 'Montando...' : 'Iniciar simulado · $_len',
                icon: Icons.play_arrow_rounded,
                onTap: (_loading || allIds.isEmpty) ? null : () => _start(allIds),
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
                    height: 1,
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
}
