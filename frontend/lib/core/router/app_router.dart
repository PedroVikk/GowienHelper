import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/flashcards/flashcard_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/quiz/quiz_screen.dart';
import '../../features/simulado/simulado_screen.dart';
import '../../features/subject_detail/subject_detail_screen.dart';
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
      pageBuilder: (_, __) => _slide(const FlashcardScreen()),
    ),
    GoRoute(
      path: '/subject',
      pageBuilder: (_, __) => _slide(const SubjectDetailScreen()),
    ),
    GoRoute(
      path: '/quiz',
      pageBuilder: (_, __) => _slide(const QuizScreen()),
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
