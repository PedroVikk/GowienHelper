/// Configuração de runtime do app (endpoint da API e chaves de persistência).
class AppConfig {
  AppConfig._();

  /// Base URL padrão: IP da máquina do backend na rede Wi-Fi local.
  /// Editável na tela de login e em Perfil → Ajustes (fica salvo).
  static const defaultBaseUrl = 'http://192.168.1.247:8000';

  /// Prefixo das rotas da API (FastAPI).
  static const apiPrefix = '/api/v1';

  // Chaves do SharedPreferences.
  static const kBaseUrlKey = 'gw_base_url';
  static const kTokenKey = 'gw_auth_token';
}
