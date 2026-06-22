import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../shared/widgets/common.dart';

/// Aba "Perfil" — usuário real (/auth/me + /stats/overview) e logout.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final overview = ref.watch(overviewProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Gw.s18, Gw.s16, Gw.s18, Gw.s24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Perfil', style: AppTheme.screenTitle),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.push('/settings'),
                    child: const Row(
                      children: [
                        Icon(Icons.settings_rounded, color: Gw.textLo, size: 19),
                        SizedBox(width: 4),
                        Text('Ajustes',
                            style: TextStyle(color: Gw.textLo, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(width: Gw.s16),
                  GestureDetector(
                    onTap: () => ref.read(settingsProvider.notifier).clearToken(),
                    child: const Row(
                      children: [
                        Icon(Icons.logout_rounded, color: Gw.textLo, size: 18),
                        SizedBox(width: 4),
                        Text('Sair',
                            style: TextStyle(color: Gw.textLo, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Gw.s16),
          user.when(
            loading: () => const SizedBox(
                height: 110,
                child: Center(child: CircularProgressIndicator(color: Gw.primary))),
            error: (e, _) => GwCard(
                child: Text('Não foi possível carregar o perfil: $e',
                    style: const TextStyle(color: Gw.textHi, fontSize: 13))),
            data: (u) => _userCard(u, overview.valueOrNull),
          ),
          const SizedBox(height: Gw.s24),
          const Overline('Conquistas'),
          const SizedBox(height: Gw.s12),
          Wrap(
            spacing: Gw.s12,
            runSpacing: Gw.s12,
            children: [
              _Achievement(Icons.bolt_rounded, 'Primeiros passos',
                  (overview.valueOrNull?.questionsAnswered ?? 0) > 0),
              _Achievement(Icons.local_fire_department_rounded, 'Constância',
                  (overview.valueOrNull?.streak ?? 0) >= 3),
              _Achievement(Icons.track_changes_rounded, 'Precisão',
                  (overview.valueOrNull?.accuracy ?? 0) >= 0.8),
              _Achievement(Icons.workspace_premium_rounded, 'Centurião',
                  (overview.valueOrNull?.xp ?? 0) >= 1000),
            ],
          ),
        ],
      ),
    );
  }

  Widget _userCard(User u, Overview? o) {
    final initial = u.name.isNotEmpty ? u.name[0].toUpperCase() : '?';
    return GwCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x388B7CF6), Color(0x1A22D3EE)],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Gw.calculo, Gw.primary]),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(initial,
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800, color: Gw.bg)),
          ),
          const SizedBox(width: Gw.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u.name,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Gw.textHi)),
                const SizedBox(height: 2),
                Text(u.email,
                    style: const TextStyle(fontSize: 12, color: Gw.textLo)),
                const SizedBox(height: 6),
                Text('Nível ${u.level} · ${u.xp} XP',
                    style: const TextStyle(color: Gw.textLo)),
                const SizedBox(height: 8),
                GwProgressBar(value: o?.levelProgress ?? 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Achievement extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool unlocked;
  const _Achievement(this.icon, this.label, this.unlocked);

  @override
  Widget build(BuildContext context) {
    final c = unlocked ? Gw.streak : Gw.textDim;
    return SizedBox(
      width: 76,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: c.withValues(alpha: 0.5)),
              boxShadow:
                  unlocked ? Gw.softGlow(c, blur: 12, alpha: 0.5) : null,
            ),
            child: Icon(icon, color: c, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11, color: unlocked ? Gw.textMid : Gw.textDim)),
        ],
      ),
    );
  }
}
