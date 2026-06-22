import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/flashcards/flashcard_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/quiz/quiz_player.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/simulado/simulado_screen.dart';
import '../../features/subjects/new_subject_screen.dart';
import '../../features/subjects/subject_studio_screen.dart';
import '../../features/themed_quiz/themed_quiz_screen.dart';

/// Transição de página: slide + fade leve (220ms), como no brief.
CustomTransitionPage<void> _slide(Widget child) {
  return CustomTransitionPage(
    transitionDuration: const Duration(milliseconds: 220),
    child: child,
    transitionsBuilder: (context, animation, secondary, child) {
      final offset = Tween<Offset>(
        begin: const Offset(0.04, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(position: offset, child: child),
      );
    },
  );
}

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (_, __) => const NoTransitionPage(child: HomeShell()),
    ),
    GoRoute(
      path: '/flashcards',
      pageBuilder: (context, state) => _slide(
        FlashcardScreen(
          subjectId: int.tryParse(state.uri.queryParameters['subject'] ?? ''),
        ),
      ),
    ),
    GoRoute(
      path: '/new-subject',
      pageBuilder: (_, __) => _slide(const NewSubjectScreen()),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (_, __) => _slide(const SettingsScreen()),
    ),
    GoRoute(
      path: '/subject-studio',
      pageBuilder: (context, state) => _slide(
        SubjectStudioScreen(
          subjectId: int.tryParse(state.uri.queryParameters['id'] ?? '') ?? 0,
        ),
      ),
    ),
    GoRoute(
      path: '/quiz-player',
      pageBuilder: (context, state) =>
          _slide(QuizPlayerScreen(args: state.extra! as QuizArgs)),
    ),
    GoRoute(
      path: '/simulado',
      pageBuilder: (_, __) => _slide(const SimuladoScreen()),
    ),
    GoRoute(
      path: '/themed-quiz',
      pageBuilder: (_, __) => _slide(const ThemedQuizScreen()),
    ),
  ],
);
