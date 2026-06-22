import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/api/providers.dart';
import 'models.dart';

// ------------------------------------------------------------------- Auth
class AuthRepository {
  final ApiClient _api;
  const AuthRepository(this._api);

  Future<User> register(String name, String email, String password) async {
    final data = await _api.post('/auth/register',
        body: {'name': name, 'email': email, 'password': password});
    return User.fromJson(data as Map<String, dynamic>);
  }

  /// Retorna o access_token.
  Future<String> login(String email, String password) async {
    final data = await _api
        .post('/auth/login', body: {'email': email, 'password': password});
    return (data as Map<String, dynamic>)['access_token'] as String;
  }

  Future<User> me() async {
    final data = await _api.get('/auth/me');
    return User.fromJson(data as Map<String, dynamic>);
  }
}

// --------------------------------------------------------------- Subjects
class SubjectsRepository {
  final ApiClient _api;
  const SubjectsRepository(this._api);

  Future<List<Subject>> list() async {
    final data = await _api.get('/subjects', query: {'limit': 100});
    final items = (data as Map<String, dynamic>)['items'] as List;
    return items
        .map((e) => Subject.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Subject> create({
    required String name,
    required String colorHex,
    required String iconName,
    String? professor,
    DateTime? examDate,
  }) async {
    final data = await _api.post('/subjects', body: {
      'name': name,
      'color': colorHex,
      'icon': iconName,
      if (professor != null && professor.isNotEmpty) 'professor': professor,
      if (examDate != null)
        'exam_date': examDate.toIso8601String().split('T').first,
    });
    return Subject.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _api.delete('/subjects/$id');
}

// --------------------------------------------------------------- Materials
class MaterialsRepository {
  final ApiClient _api;
  const MaterialsRepository(this._api);

  Future<List<Material>> list(int subjectId) async {
    final data = await _api.get('/subjects/$subjectId/materials');
    final items = (data as Map<String, dynamic>)['items'] as List;
    return items
        .map((e) => Material.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Material> upload(
    int subjectId,
    List<int> bytes,
    String filename,
  ) async {
    final file = MultipartFile.fromBytes(bytes, filename: filename);
    final data = await _api.upload('/subjects/$subjectId/materials', file);
    return Material.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(int subjectId, int materialId) =>
      _api.delete('/subjects/$subjectId/materials/$materialId');
}

// -------------------------------------------------------------- Generation
class GenerationRepository {
  final ApiClient _api;
  const GenerationRepository(this._api);

  Future<Summary> summary(int subjectId) async {
    final data = await _api.post('/subjects/$subjectId/generate/summary');
    return Summary.fromJson(data as Map<String, dynamic>);
  }

  Future<String> mindmap(int subjectId) async {
    final data = await _api.post('/subjects/$subjectId/generate/mindmap');
    return (data as Map<String, dynamic>)['markdown'] as String;
  }

  Future<List<Flashcard>> flashcards(int subjectId, {int count = 10}) async {
    final data = await _api
        .post('/subjects/$subjectId/generate/flashcards', body: {'count': count});
    return (data as List)
        .map((e) => Flashcard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Quiz> quiz(int subjectId, {int count = 10}) async {
    final data = await _api
        .post('/subjects/$subjectId/generate/quiz', body: {'count': count});
    return Quiz.fromJson(data as Map<String, dynamic>);
  }

  /// Quiz travado em um tema (híbrido material/IA).
  Future<List<Question>> themedQuiz(
    int subjectId, {
    required String theme,
    int count = 10,
    String difficulty = 'medium',
  }) async {
    final data = await _api.post('/subjects/$subjectId/quiz/themed', body: {
      'theme': theme,
      'count': count,
      'difficulty': difficulty,
    });
    final questions = (data as Map<String, dynamic>)['questions'] as List;
    return questions
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// -------------------------------------------------------------- Flashcards
class FlashcardsRepository {
  final ApiClient _api;
  const FlashcardsRepository(this._api);

  Future<List<Flashcard>> list(int subjectId, {bool dueOnly = false}) async {
    final data = await _api.get('/subjects/$subjectId/flashcards',
        query: dueOnly ? {'due_only': true} : null);
    return (data as List)
        .map((e) => Flashcard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Registra uma revisão (SM-2): quality 0-2 errou, 3 difícil, 4 bom, 5 fácil.
  Future<void> review(int cardId, int quality) =>
      _api.post('/flashcards/$cardId/review', body: {'quality': quality});
}

// ------------------------------------------------------------------ Study
class StudyRepository {
  final ApiClient _api;
  const StudyRepository(this._api);

  /// Monta um simulado misturando questões das disciplinas (sem gabarito local).
  Future<List<Question>> simulado(int count, List<int> subjectIds) async {
    final data = await _api.post('/simulados',
        body: {'count': count, 'subject_ids': subjectIds});
    final questions = (data as Map<String, dynamic>)['questions'] as List;
    return questions
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Responde uma questão (correção no servidor) e retorna se acertou + feedback.
  Future<({bool isCorrect, String feedback})> answer(
    int questionId,
    String answer, {
    int timeSpent = 0,
  }) async {
    final data = await _api.post('/questions/$questionId/answer',
        body: {'answer': answer, 'time_spent_seconds': timeSpent});
    final m = data as Map<String, dynamic>;
    return (
      isCorrect: (m['is_correct'] ?? false) as bool,
      feedback: (m['feedback'] ?? '') as String,
    );
  }
}

// ------------------------------------------------------------------ Stats
class StatsRepository {
  final ApiClient _api;
  const StatsRepository(this._api);

  Future<Overview> overview() async {
    final data = await _api.get('/stats/overview');
    return Overview.fromJson(data as Map<String, dynamic>);
  }

  Future<List<SubjectStat>> bySubject() async {
    final data = await _api.get('/stats/by-subject');
    return (data as List)
        .map((e) => SubjectStat.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DailyStat>> evolution({int days = 7}) async {
    final data = await _api.get('/stats/evolution', query: {'days': days});
    return (data as List)
        .map((e) => DailyStat.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ------------------------------------------------------------------ Health
class HealthRepository {
  final ApiClient _api;
  const HealthRepository(this._api);

  Future<bool> ping() async {
    try {
      await _api.get('/health');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Status rico da IA: provedor ativo, disponibilidade e uso (cota).
  Future<Map<String, dynamic>> ai() async =>
      (await _api.get('/ai/status')) as Map<String, dynamic>;

  /// Troca a IA entre "ollama" (local) e "gemini" (nuvem).
  Future<Map<String, dynamic>> setProvider(String provider) async =>
      (await _api.post('/ai/provider', body: {'provider': provider}))
          as Map<String, dynamic>;
}

// -------------------------------------------------------------- Providers
final authRepositoryProvider =
    Provider((ref) => AuthRepository(ref.watch(apiProvider)));
final subjectsRepositoryProvider =
    Provider((ref) => SubjectsRepository(ref.watch(apiProvider)));
final materialsRepositoryProvider =
    Provider((ref) => MaterialsRepository(ref.watch(apiProvider)));
final generationRepositoryProvider =
    Provider((ref) => GenerationRepository(ref.watch(apiProvider)));
final statsRepositoryProvider =
    Provider((ref) => StatsRepository(ref.watch(apiProvider)));
final flashcardsRepositoryProvider =
    Provider((ref) => FlashcardsRepository(ref.watch(apiProvider)));
final healthRepositoryProvider =
    Provider((ref) => HealthRepository(ref.watch(apiProvider)));
final studyRepositoryProvider =
    Provider((ref) => StudyRepository(ref.watch(apiProvider)));

/// Status da IA (provedor/modelo/conectividade). Recarrega ao trocar servidor.
final aiStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  ref.watch(settingsProvider.select((s) => s.baseUrl));
  return ref.watch(healthRepositoryProvider).ai();
});

/// Flashcards de uma disciplina (invalidável após gerar/revisar).
final flashcardsProvider =
    FutureProvider.family<List<Flashcard>, int>((ref, subjectId) async {
  ref.watch(settingsProvider.select((s) => s.token));
  return ref.watch(flashcardsRepositoryProvider).list(subjectId);
});

/// Usuário autenticado (recarrega quando o token muda).
final currentUserProvider = FutureProvider<User>((ref) async {
  ref.watch(settingsProvider.select((s) => s.token));
  return ref.watch(authRepositoryProvider).me();
});

/// Lista de disciplinas do usuário (fonte única para telas).
final subjectsListProvider = FutureProvider<List<Subject>>((ref) async {
  ref.watch(settingsProvider.select((s) => s.token));
  return ref.watch(subjectsRepositoryProvider).list();
});

/// Overview de stats/gamificação (dashboard e aba Stats).
final overviewProvider = FutureProvider<Overview>((ref) async {
  ref.watch(settingsProvider.select((s) => s.token));
  return ref.watch(statsRepositoryProvider).overview();
});

/// Materiais de uma disciplina (invalidável após upload).
final materialsProvider =
    FutureProvider.family<List<Material>, int>((ref, subjectId) async {
  ref.watch(settingsProvider.select((s) => s.token));
  return ref.watch(materialsRepositoryProvider).list(subjectId);
});

/// Desempenho por disciplina (aba Stats).
final bySubjectProvider = FutureProvider<List<SubjectStat>>((ref) async {
  ref.watch(settingsProvider.select((s) => s.token));
  return ref.watch(statsRepositoryProvider).bySubject();
});

/// Evolução diária (aba Stats).
final evolutionProvider = FutureProvider<List<DailyStat>>((ref) async {
  ref.watch(settingsProvider.select((s) => s.token));
  return ref.watch(statsRepositoryProvider).evolution(days: 7);
});
