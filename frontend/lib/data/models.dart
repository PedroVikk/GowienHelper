import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';

// ---------------------------------------------------------------- helpers

/// Converte "#RRGGBB" (ou "#AARRGGBB") em [Color].
Color colorFromHex(String hex) {
  var h = hex.replaceAll('#', '').trim();
  if (h.length == 6) h = 'FF$h';
  final value = int.tryParse(h, radix: 16);
  return value == null ? Gw.primary : Color(value);
}

/// Converte [Color] em "#RRGGBB".
String hexFromColor(Color c) {
  final argb = c.toARGB32();
  return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// Ícones de disciplina (nome no backend <-> IconData no app).
const kSubjectIconByName = <String, IconData>{
  'calculate': Icons.calculate_rounded,
  'biotech': Icons.biotech_rounded,
  'code': Icons.code_rounded,
  'psychology': Icons.psychology_rounded,
  'science': Icons.science_rounded,
  'book': Icons.menu_book_rounded,
  'history': Icons.history_edu_rounded,
  'public': Icons.public_rounded,
  'gavel': Icons.gavel_rounded,
  'favorite': Icons.favorite_rounded,
  'school': Icons.school_rounded,
};

IconData iconFromName(String? name) =>
    kSubjectIconByName[name] ?? Icons.menu_book_rounded;

String nameFromIcon(IconData icon) => kSubjectIconByName.entries
    .firstWhere((e) => e.value == icon,
        orElse: () => const MapEntry('book', Icons.menu_book_rounded))
    .key;

// ---------------------------------------------------------------- models

class User {
  final int id;
  final String name;
  final String email;
  final int xp;
  final int level;
  final int streak;
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.xp,
    required this.level,
    required this.streak,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] as int,
        name: j['name'] as String,
        email: j['email'] as String,
        xp: (j['xp'] ?? 0) as int,
        level: (j['level'] ?? 1) as int,
        streak: (j['streak'] ?? 0) as int,
      );
}

/// Disciplina (espelha SubjectResponse). Cor/ícone resolvidos para UI.
class Subject {
  final int id;
  final String name;
  final Color color;
  final IconData icon;
  final String? professor;
  final String? description;
  final DateTime? examDate;

  const Subject({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    this.professor,
    this.description,
    this.examDate,
  });

  factory Subject.fromJson(Map<String, dynamic> j) => Subject(
        id: j['id'] as int,
        name: j['name'] as String,
        color: colorFromHex((j['color'] ?? '#8B7CF6') as String),
        icon: iconFromName(j['icon'] as String?),
        professor: j['professor'] as String?,
        description: j['description'] as String?,
        examDate: j['exam_date'] != null
            ? DateTime.tryParse(j['exam_date'] as String)
            : null,
      );
}

class Material {
  final int id;
  final String filename;
  final String fileType;
  final String status; // pending | extracted | processed | failed
  final int textLength;
  const Material({
    required this.id,
    required this.filename,
    required this.fileType,
    required this.status,
    required this.textLength,
  });

  factory Material.fromJson(Map<String, dynamic> j) => Material(
        id: j['id'] as int,
        filename: j['filename'] as String,
        fileType: (j['file_type'] ?? '') as String,
        status: (j['status'] ?? 'pending') as String,
        textLength: (j['text_length'] ?? 0) as int,
      );
}

class Flashcard {
  final int id;
  final String front;
  final String back;
  final bool isFavorite;
  final bool isManual;
  const Flashcard({
    required this.id,
    required this.front,
    required this.back,
    this.isFavorite = false,
    this.isManual = false,
  });

  factory Flashcard.fromJson(Map<String, dynamic> j) => Flashcard(
        id: (j['id'] ?? 0) as int,
        front: (j['front'] ?? '') as String,
        back: (j['back'] ?? '') as String,
        isFavorite: (j['is_favorite'] ?? false) as bool,
        isManual: (j['is_manual'] ?? false) as bool,
      );
}

class Question {
  final int? id;
  final String type;
  final String prompt;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  const Question({
    this.id,
    required this.type,
    required this.prompt,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> j) => Question(
        id: j['id'] as int?,
        type: (j['type'] ?? 'multiple_choice') as String,
        prompt: (j['prompt'] ?? '') as String,
        options: ((j['options'] ?? []) as List).map((e) => '$e').toList(),
        correctAnswer: (j['correct_answer'] ?? '').toString(),
        explanation: (j['explanation'] ?? '') as String,
      );

  /// Índice da alternativa correta (para múltipla escolha), -1 se não achar.
  int get correctIndex {
    final byText = options.indexOf(correctAnswer);
    if (byText != -1) return byText;
    final asInt = int.tryParse(correctAnswer);
    if (asInt != null && asInt >= 0 && asInt < options.length) return asInt;
    return -1;
  }
}

class Quiz {
  final int id;
  final String title;
  final String kind;
  final List<Question> questions;
  const Quiz({
    required this.id,
    required this.title,
    required this.kind,
    required this.questions,
  });

  factory Quiz.fromJson(Map<String, dynamic> j) => Quiz(
        id: (j['id'] ?? 0) as int,
        title: (j['title'] ?? 'Quiz') as String,
        kind: (j['kind'] ?? 'quiz') as String,
        questions: ((j['questions'] ?? []) as List)
            .map((e) => Question.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Summary {
  final String short;
  final String full;
  final List<String> topics;
  final Map<String, String> glossary;
  final List<String> formulas;
  const Summary({
    required this.short,
    required this.full,
    required this.topics,
    required this.glossary,
    required this.formulas,
  });

  factory Summary.fromJson(Map<String, dynamic> j) => Summary(
        short: (j['short'] ?? '') as String,
        full: (j['full'] ?? '') as String,
        topics: ((j['topics'] ?? []) as List).map((e) => '$e').toList(),
        glossary: ((j['glossary'] ?? {}) as Map)
            .map((k, v) => MapEntry('$k', '$v')),
        formulas: ((j['formulas'] ?? []) as List).map((e) => '$e').toList(),
      );
}

class Overview {
  final int questionsAnswered;
  final int correctAnswers;
  final double accuracy;
  final int timeStudiedSeconds;
  final int xp;
  final int level;
  final int xpInLevel;
  final int xpToNextLevel;
  final int streak;
  const Overview({
    required this.questionsAnswered,
    required this.correctAnswers,
    required this.accuracy,
    required this.timeStudiedSeconds,
    required this.xp,
    required this.level,
    required this.xpInLevel,
    required this.xpToNextLevel,
    required this.streak,
  });

  factory Overview.fromJson(Map<String, dynamic> j) => Overview(
        questionsAnswered: (j['questions_answered'] ?? 0) as int,
        correctAnswers: (j['correct_answers'] ?? 0) as int,
        accuracy: ((j['accuracy'] ?? 0) as num).toDouble(),
        timeStudiedSeconds: (j['time_studied_seconds'] ?? 0) as int,
        xp: (j['xp'] ?? 0) as int,
        level: (j['level'] ?? 1) as int,
        xpInLevel: (j['xp_in_level'] ?? 0) as int,
        xpToNextLevel: (j['xp_to_next_level'] ?? 100) as int,
        streak: (j['streak'] ?? 0) as int,
      );

  double get levelProgress =>
      xpToNextLevel <= 0 ? 0 : (xpInLevel / (xpInLevel + xpToNextLevel));
}

class SubjectStat {
  final int subjectId;
  final String name;
  final int answered;
  final int correct;
  final double accuracy;
  const SubjectStat({
    required this.subjectId,
    required this.name,
    required this.answered,
    required this.correct,
    required this.accuracy,
  });

  factory SubjectStat.fromJson(Map<String, dynamic> j) => SubjectStat(
        subjectId: (j['subject_id'] ?? 0) as int,
        name: (j['name'] ?? '') as String,
        answered: (j['answered'] ?? 0) as int,
        correct: (j['correct'] ?? 0) as int,
        accuracy: ((j['accuracy'] ?? 0) as num).toDouble(),
      );
}

class DailyStat {
  final String day;
  final int answered;
  final int correct;
  const DailyStat({
    required this.day,
    required this.answered,
    required this.correct,
  });

  factory DailyStat.fromJson(Map<String, dynamic> j) => DailyStat(
        day: (j['day'] ?? '') as String,
        answered: (j['answered'] ?? 0) as int,
        correct: (j['correct'] ?? 0) as int,
      );
}
