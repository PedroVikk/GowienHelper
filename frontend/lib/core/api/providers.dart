import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'api_client.dart';

/// Sobrescrito em main() com a instância real (carregada de forma assíncrona).
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider não inicializado'),
);

/// Configurações persistidas: endereço do servidor + token JWT.
class AppSettings {
  final String baseUrl;
  final String? token;
  const AppSettings({required this.baseUrl, this.token});

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  AppSettings copyWith({String? baseUrl, String? token, bool clearToken = false}) {
    return AppSettings(
      baseUrl: baseUrl ?? this.baseUrl,
      token: clearToken ? null : (token ?? this.token),
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences _prefs;
  SettingsNotifier(this._prefs)
      : super(AppSettings(
          baseUrl: _prefs.getString(AppConfig.kBaseUrlKey) ??
              AppConfig.defaultBaseUrl,
          token: _prefs.getString(AppConfig.kTokenKey),
        ));

  Future<void> setBaseUrl(String url) async {
    final clean = url.trim().replaceAll(RegExp(r'/+$'), '');
    await _prefs.setString(AppConfig.kBaseUrlKey, clean);
    state = state.copyWith(baseUrl: clean);
  }

  Future<void> setToken(String token) async {
    await _prefs.setString(AppConfig.kTokenKey, token);
    state = state.copyWith(token: token);
  }

  Future<void> clearToken() async {
    await _prefs.remove(AppConfig.kTokenKey);
    state = state.copyWith(clearToken: true);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(ref.watch(sharedPrefsProvider)),
);

/// Dio configurado com baseUrl + prefixo + token (reage a mudanças nas settings).
final dioProvider = Provider<Dio>((ref) {
  final settings = ref.watch(settingsProvider);
  final dio = Dio(BaseOptions(
    baseUrl: '${settings.baseUrl}${AppConfig.apiPrefix}',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 300), // geração de IA é lenta
    sendTimeout: const Duration(seconds: 60),
    headers: {
      'Content-Type': 'application/json',
      // Pula a página de aviso do ngrok grátis em requisições do app.
      'ngrok-skip-browser-warning': 'true',
    },
  ));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = settings.token;
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
  ));
  return dio;
});

final apiProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioProvider)),
);
