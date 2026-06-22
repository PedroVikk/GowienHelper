import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';

class GoWiseApp extends ConsumerWidget {
  const GoWiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(settingsProvider.select((s) => s.isLoggedIn));
    if (!loggedIn) {
      return MaterialApp(
        title: 'GoWise Helper',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: const LoginScreen(),
      );
    }
    return MaterialApp.router(
      title: 'GoWise Helper',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: appRouter,
    );
  }
}
