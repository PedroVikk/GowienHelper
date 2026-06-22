import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/providers.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories.dart';
import '../../shared/widgets/common.dart';

/// Login / cadastro. Quando o token é salvo, o app troca automaticamente
/// para a navegação principal (ver app.dart).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final TextEditingController _server;

  bool _register = false;
  bool _loading = false;
  bool _showServer = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _server = TextEditingController(text: ref.read(settingsProvider).baseUrl);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _server.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final settings = ref.read(settingsProvider.notifier);
      await settings.setBaseUrl(_server.text);
      final auth = ref.read(authRepositoryProvider);
      if (_register) {
        await auth.register(
            _name.text.trim(), _email.text.trim(), _password.text);
      }
      final token = await auth.login(_email.text.trim(), _password.text);
      await settings.setToken(token); // app troca para a Home
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Erro inesperado: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(Gw.s24),
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: Gw.gradBrand,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: Gw.glow(Gw.primary, blur: 20, alpha: 0.5),
                ),
                child: const Icon(Icons.school_rounded, color: Gw.bg, size: 34),
              ),
              const SizedBox(height: Gw.s16),
              const Text('GoWise Helper',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Gw.textHi)),
              const SizedBox(height: 4),
              Text(_register ? 'Crie sua conta' : 'Entre para continuar',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Gw.textLo)),
              const SizedBox(height: Gw.s24),
              if (_register) ...[
                _field(_name, 'Nome', Icons.person_rounded),
                const SizedBox(height: Gw.s12),
              ],
              _field(_email, 'E-mail', Icons.mail_rounded,
                  keyboard: TextInputType.emailAddress),
              const SizedBox(height: Gw.s12),
              _field(_password, 'Senha', Icons.lock_rounded, obscure: true),
              const SizedBox(height: Gw.s12),
              if (_showServer)
                _field(_server, 'Servidor (URL)', Icons.dns_rounded,
                    keyboard: TextInputType.url),
              if (_showServer) const SizedBox(height: Gw.s12),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Gw.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(Gw.rChip),
                    border: Border.all(color: Gw.error.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Gw.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                fontSize: 13, color: Gw.textHi)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Gw.s12),
              ],
              GlowButton(
                label: _loading
                    ? 'Aguarde...'
                    : (_register ? 'Cadastrar' : 'Entrar'),
                icon: _register ? Icons.person_add_rounded : Icons.login_rounded,
                onTap: _loading ? null : _submit,
              ),
              const SizedBox(height: Gw.s16),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() {
                          _register = !_register;
                          _error = null;
                        }),
                child: Text(
                  _register
                      ? 'Já tenho conta — entrar'
                      : 'Não tenho conta — cadastrar',
                  style: const TextStyle(color: Gw.primary),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _showServer = !_showServer),
                child: Text(
                  _showServer ? 'Ocultar servidor' : 'Configurar servidor',
                  style: const TextStyle(color: Gw.textDim, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String hint,
    IconData icon, {
    bool obscure = false,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: Gw.textHi, fontSize: 15),
      cursorColor: Gw.primary,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Gw.textDim),
        prefixIcon: Icon(icon, color: Gw.primary, size: 20),
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
}
