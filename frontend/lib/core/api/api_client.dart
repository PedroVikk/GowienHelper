import 'package:dio/dio.dart';

/// Erro de API normalizado (mensagem amigável + status HTTP).
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Wrapper fino sobre o Dio: centraliza chamadas e converte qualquer falha
/// em [ApiException] (lendo o campo `detail` que o backend retorna nos erros).
class ApiClient {
  final Dio _dio;
  const ApiClient(this._dio);

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? body}) =>
      _send(() => _dio.post(path, data: body));

  Future<dynamic> patch(String path, {Object? body}) =>
      _send(() => _dio.patch(path, data: body));

  Future<void> delete(String path) async {
    await _send(() => _dio.delete(path));
  }

  /// Upload multipart (usado no envio de materiais).
  Future<dynamic> upload(String path, MultipartFile file) => _send(
        () => _dio.post(path, data: FormData.fromMap({'file': file})),
      );

  Future<dynamic> _send(Future<Response> Function() call) async {
    try {
      final resp = await call();
      return resp.data;
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  ApiException _map(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) {
      return ApiException(data['detail'].toString(), statusCode: status);
    }
    final msg = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Tempo de conexão esgotado. A IA pode levar um tempo na 1ª geração.',
      DioExceptionType.connectionError =>
        'Sem conexão com o servidor. Confira o endereço e se o backend está no ar.',
      _ => status != null ? 'Erro $status do servidor.' : 'Falha de rede.',
    };
    return ApiException(msg, statusCode: status);
  }
}
