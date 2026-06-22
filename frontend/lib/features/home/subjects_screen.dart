import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../shared/widgets/common.dart';

/// Aba "Disciplinas": atalhos + lista de matérias vinda do backend.
class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsListProvider);
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: Gw.primary,
        backgroundColor: Gw.card,
        onRefresh: () async => ref.refresh(subjectsListProvider.future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Gw.s18, Gw.s16, Gw.s18, Gw.s24),
          children: [
            Row(
              children: [
                Text('Disciplinas', style: AppTheme.screenTitle),
                const Spacer(),
                _newButton(context),
              ],
            ),
            const SizedBox(height: Gw.s16),
            Row(
              children: [
                Expanded(
                  child: GlowButton(
                    label: 'Simulado',
                    icon: Icons.timer_outlined,
                    onTap: () => context.push('/simulado'),
                  ),
                ),
                const SizedBox(width: Gw.s12),
                Expanded(
                  child: GlowButton(
                    label: 'Quiz por tema',
                    icon: Icons.lock_outline_rounded,
                    gradient: Gw.gradAccent,
                    glowColor: Gw.accent,
                    onTap: () => context.push('/themed-quiz'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gw.s24),
            const Overline('Suas matérias'),
            const SizedBox(height: Gw.s12),
            subjectsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: Gw.s24),
                child: Center(child: CircularProgressIndicator(color: Gw.primary)),
              ),
              error: (e, _) => _error('$e'),
              data: (subjects) => subjects.isEmpty
                  ? _empty(context)
                  : Column(
                      children: subjects
                          .map((s) => _subjectCard(context, s))
                          .toList()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _newButton(BuildContext context) => GestureDetector(
        onTap: () => context.push('/new-subject'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            gradient: Gw.gradPrimary,
            borderRadius: BorderRadius.circular(Gw.rPill),
            boxShadow: Gw.softGlow(Gw.primary, blur: 12, alpha: 0.5),
          ),
          child: const Row(
            children: [
              Icon(Icons.add_rounded, color: Gw.bg, size: 18),
              SizedBox(width: 4),
              Text('Nova',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: Gw.bg)),
            ],
          ),
        ),
      );

  Widget _subjectCard(BuildContext context, Subject s) => Padding(
        padding: const EdgeInsets.only(bottom: Gw.s12),
        child: GwCard(
          padding: const EdgeInsets.all(14),
          radius: Gw.rCard,
          child: InkWell(
            onTap: () => context.push('/subject-studio?id=${s.id}'),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: s.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: s.color.withValues(alpha: 0.4)),
                  ),
                  child: Icon(s.icon, color: s.color, size: 22),
                ),
                const SizedBox(width: Gw.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Gw.textHi)),
                      const SizedBox(height: 2),
                      Text(s.professor ?? 'Toque para estudar com IA',
                          style:
                              const TextStyle(fontSize: 12, color: Gw.textLo)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Gw.textDim),
              ],
            ),
          ),
        ),
      );

  Widget _empty(BuildContext context) => Container(
        padding: const EdgeInsets.all(Gw.s24),
        decoration: BoxDecoration(
          color: Gw.card,
          borderRadius: BorderRadius.circular(Gw.rCard),
          border: Border.all(color: Gw.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.menu_book_rounded, color: Gw.textDim, size: 32),
            const SizedBox(height: 12),
            const Text('Nenhuma disciplina ainda',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Gw.textHi)),
            const SizedBox(height: 4),
            const Text('Crie sua primeira matéria e envie um material.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Gw.textLo)),
            const SizedBox(height: Gw.s16),
            GlowButton(
              label: 'Nova disciplina',
              icon: Icons.add_rounded,
              onTap: () => context.push('/new-subject'),
            ),
          ],
        ),
      );

  Widget _error(String msg) => Container(
        padding: const EdgeInsets.all(Gw.s16),
        decoration: BoxDecoration(
          color: Gw.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Gw.rCard),
          border: Border.all(color: Gw.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Gw.error, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Não foi possível carregar: $msg',
                  style: const TextStyle(fontSize: 13, color: Gw.textHi)),
            ),
          ],
        ),
      );
}
