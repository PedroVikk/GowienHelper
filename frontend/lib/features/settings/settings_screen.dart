import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/providers.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories.dart';
import '../../shared/widgets/common.dart';

/// Ajustes: configurar o servidor e ver o status da IA (Qwen3/Ollama).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _server;
  String? _pingMsg;
  bool _pingOk = false;
  bool _testing = false;
  bool _switching = false;

  @override
  void initState() {
    super.initState();
    _server = TextEditingController(text: ref.read(settingsProvider).baseUrl);
  }

  @override
  void dispose() {
    _server.dispose();
    super.dispose();
  }

  Future<void> _saveAndTest() async {
    setState(() {
      _testing = true;
      _pingMsg = null;
    });
    await ref.read(settingsProvider.notifier).setBaseUrl(_server.text);
    final ok = await ref.read(healthRepositoryProvider).ping();
    ref.invalidate(aiStatusProvider);
    if (mounted) {
      setState(() {
        _testing = false;
        _pingOk = ok;
        _pingMsg = ok ? 'Conectado ao servidor ✓' : 'Sem resposta do servidor';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ai = ref.watch(aiStatusProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
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
                    child: Text('Ajustes',
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
                padding:
                    const EdgeInsets.fromLTRB(Gw.s18, Gw.s8, Gw.s18, Gw.s24),
                children: [
                  const Overline('Servidor'),
                  const SizedBox(height: Gw.s12),
                  _serverField(),
                  const SizedBox(height: Gw.s12),
                  GlowButton(
                    label: _testing ? 'Testando...' : 'Salvar e testar conexão',
                    icon: Icons.wifi_tethering_rounded,
                    onTap: _testing ? null : _saveAndTest,
                  ),
                  if (_pingMsg != null) ...[
                    const SizedBox(height: Gw.s12),
                    _statusLine(_pingOk, _pingMsg!),
                  ],
                  const SizedBox(height: Gw.s24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Overline('Inteligência Artificial'),
                      GestureDetector(
                        onTap: () => ref.invalidate(aiStatusProvider),
                        child: const Icon(Icons.refresh_rounded,
                            color: Gw.textLo, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: Gw.s12),
                  ai.when(
                    loading: () => const GwCard(
                      child: Center(
                          child: CircularProgressIndicator(color: Gw.primary)),
                    ),
                    error: (e, _) => _aiOffline(),
                    data: _aiCard,
                  ),
                  const SizedBox(height: Gw.s24),
                  const Overline('Onde a IA é usada'),
                  const SizedBox(height: Gw.s12),
                  _usageCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _serverField() {
    return TextField(
      controller: _server,
      keyboardType: TextInputType.url,
      autocorrect: false,
      style: const TextStyle(color: Gw.textHi, fontSize: 15),
      cursorColor: Gw.primary,
      decoration: InputDecoration(
        hintText: 'http://192.168.x.x:8000',
        hintStyle: const TextStyle(color: Gw.textDim),
        prefixIcon: const Icon(Icons.dns_rounded, color: Gw.primary, size: 20),
        filled: true,
        fillColor: Gw.card,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Gw.rCard),
          borderSide: const BorderSide(color: Gw.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Gw.rCard),
          borderSide: const BorderSide(color: Gw.primary, width: 1.5),
        ),
      ),
    );
  }

  Future<void> _switchProvider(String id) async {
    setState(() => _switching = true);
    try {
      final r = await ref.read(healthRepositoryProvider).setProvider(id);
      if (r['ok'] != true) {
        _snack(r['error']?.toString() ?? 'Não foi possível trocar a IA.');
      }
      ref.invalidate(aiStatusProvider);
    } catch (e) {
      _snack('Erro ao trocar a IA: $e');
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m),
        backgroundColor: Gw.card,
        behavior: SnackBarBehavior.floating));
  }

  Widget _aiCard(Map<String, dynamic> s) {
    final active = s['active']?.toString() ?? 'ollama';
    final online = s['online'] == true;
    final providers = (s['providers'] as List?) ?? const [];
    final usage = s['usage'] as Map<String, dynamic>?;

    return Column(
      children: [
        GwCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: Gw.gradBrand,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Gw.bg, size: 22),
                  ),
                  const SizedBox(width: Gw.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${s['model'] ?? '—'}',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Gw.textHi)),
                        Text('Em uso: ${s['active_label'] ?? '—'}',
                            style: const TextStyle(
                                fontSize: 12, color: Gw.textLo)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gw.s16),
              // Seletor Local / Nuvem
              Row(
                children: [
                  for (final p in providers)
                    Expanded(child: _providerOption(p as Map<String, dynamic>, active)),
                ],
              ),
              const SizedBox(height: Gw.s12),
              _statusLine(online,
                  online ? 'IA acessível' : 'IA fora do ar (verifique abaixo)'),
            ],
          ),
        ),
        if (usage != null && usage['message'] != null) ...[
          const SizedBox(height: Gw.s12),
          _usageWarning(usage),
        ],
      ],
    );
  }

  Widget _providerOption(Map<String, dynamic> p, String active) {
    final id = p['id']?.toString() ?? '';
    final isActive = id == active;
    final available = p['available'] == true;
    final enabled = available && !isActive && !_switching;
    final color = id == 'gemini' ? Gw.accent : Gw.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: GestureDetector(
        onTap: enabled ? () => _switchProvider(id) : null,
        child: Opacity(
          opacity: (available || isActive) ? 1 : 0.5,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isActive ? color.withValues(alpha: 0.16) : Gw.card,
              borderRadius: BorderRadius.circular(Gw.rChip),
              border: Border.all(
                  color: isActive ? color : Gw.border, width: isActive ? 1.5 : 1),
            ),
            child: Column(
              children: [
                Icon(id == 'gemini' ? Icons.cloud_rounded : Icons.computer_rounded,
                    color: isActive ? color : Gw.textLo, size: 20),
                const SizedBox(height: 4),
                Text('${p['label'] ?? id}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isActive ? Gw.textHi : Gw.textLo)),
                if (!available)
                  const Text('indisponível',
                      style: TextStyle(fontSize: 10, color: Gw.textDim)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _usageWarning(Map<String, dynamic> u) {
    final exhausted = u['exhausted'] == true;
    final color = exhausted ? Gw.error : Gw.streak;
    final used = u['used_today'] ?? 0;
    final limit = u['limit'] ?? 0;
    final frac = (limit is int && limit > 0)
        ? ((used as int) / limit).clamp(0.0, 1.0)
        : 0.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Gw.rCard),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(exhausted ? Icons.battery_alert_rounded : Icons.info_rounded,
                  color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${u['message']}',
                    style: const TextStyle(
                        fontSize: 13, height: 1.4, color: Gw.textHi)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GwProgressBar(
            value: frac,
            gradient: LinearGradient(colors: [color, color]),
            glowColor: color,
          ),
          const SizedBox(height: 4),
          Text('$used / $limit gerações hoje',
              style: const TextStyle(fontSize: 11, color: Gw.textLo)),
        ],
      ),
    );
  }

  Widget _aiOffline() => GwCard(
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Gw.error, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Não foi possível falar com o backend. Verifique o servidor acima.',
                style: TextStyle(fontSize: 13, color: Gw.textHi),
              ),
            ),
          ],
        ),
      );

  Widget _usageCard() => GwCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _UsageRow(Icons.summarize_rounded, 'Resumo',
                'Resumo + tópicos + fórmulas do material'),
            SizedBox(height: 12),
            _UsageRow(Icons.style_rounded, 'Flashcards',
                'Cartões de revisão gerados do material'),
            SizedBox(height: 12),
            _UsageRow(Icons.bolt_rounded, 'Quiz',
                'Questões com explicação a partir do material'),
            SizedBox(height: 14),
            Text(
              'Abra uma disciplina → Estúdio → Gerar. A IA usa o texto dos materiais enviados.',
              style: TextStyle(fontSize: 12, color: Gw.textLo, height: 1.4),
            ),
          ],
        ),
      );

  Widget _statusLine(bool ok, String text) {
    final c = ok ? Gw.success : Gw.error;
    return Row(
      children: [
        Icon(ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: c, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, color: Gw.textHi)),
        ),
      ],
    );
  }

}

class _UsageRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _UsageRow(this.icon, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Gw.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Gw.textHi)),
              Text(subtitle,
                  style: const TextStyle(fontSize: 12, color: Gw.textLo)),
            ],
          ),
        ),
      ],
    );
  }
}
