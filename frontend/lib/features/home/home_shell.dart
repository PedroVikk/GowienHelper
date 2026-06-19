import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/app_bottom_nav.dart';
import '../dashboard/dashboard_screen.dart';
import '../stats/stats_screen.dart';
import 'profile_screen.dart';
import 'subjects_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  Widget _currentScreen() {
    switch (_index) {
      case 1:
        return const SubjectsScreen();
      case 2:
        return const StatsScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(child: _currentScreen()),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        onReview: () => context.push('/flashcards'),
      ),
    );
  }
}
