import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';

/// Dados de exemplo (espelham as props do protótipo). Em produção viriam da API.

class Discipline {
  final String name;
  final Color color;
  final int progress; // 0-100
  final int cardsToReview;
  const Discipline(this.name, this.color, this.progress, this.cardsToReview);
}

class Mission {
  final IconData icon;
  final String title;
  final int done;
  final int total;
  final int reward;
  const Mission(this.icon, this.title, this.done, this.total, this.reward);
}

class FlashcardData {
  final String question;
  final String answer;
  final String hint;
  final String mnemonic;
  final int mastery; // 0-5
  const FlashcardData({
    required this.question,
    required this.answer,
    required this.hint,
    required this.mnemonic,
    required this.mastery,
  });
}

class QuizQuestion {
  final String prompt;
  final List<String> options;
  final int correct;
  final String explanation;
  const QuizQuestion(this.prompt, this.options, this.correct, this.explanation);
}

class SimuladoHistory {
  final String label;
  final String date;
  final double score; // 0-10
  const SimuladoHistory(this.label, this.date, this.score);
}

class MockData {
  static const studentName = 'Marina';
  static const streakDays = 12;

  static const disciplines = <Discipline>[
    Discipline('Cálculo I', Gw.calculo, 68, 12),
    Discipline('Anatomia', Gw.anatomia, 45, 8),
    Discipline('Algoritmos', Gw.algoritmos, 82, 3),
    Discipline('Psicologia', Gw.psicologia, 30, 15),
    Discipline('Bioquímica', Gw.bioquimica, 54, 6),
  ];

  static const missions = <Mission>[
    Mission(Icons.repeat_rounded, 'Revisar 20 cartões', 12, 20, 50),
    Mission(Icons.bolt_rounded, 'Acertar 10 questões', 7, 10, 30),
    Mission(Icons.local_fire_department_rounded, 'Manter a ofensiva', 1, 1, 20),
  ];

  static const flashcards = <FlashcardData>[
    FlashcardData(
      question: 'Qual a derivada de sen(x)?',
      answer: 'cos(x)',
      hint: 'Pense no "co" virando o seno…',
      mnemonic: 'Seno deriva pra cosseno; cosseno deriva pra MENOS seno (ciclo S -> C -> -S -> -C).',
      mastery: 3,
    ),
    FlashcardData(
      question: 'O que é um limite lateral?',
      answer: 'O valor que a função se aproxima por um único lado (esquerda ou direita).',
      hint: 'Aproxima por um lado: esquerda ou direita',
      mnemonic: 'Lateral = um lado só. Os dois iguais => o limite existe.',
      mastery: 2,
    ),
    FlashcardData(
      question: 'Regra da cadeia: d/dx f(g(x)) = ?',
      answer: "f'(g(x)) · g'(x)",
      hint: 'Derive de fora pra dentro',
      mnemonic: 'Casca primeiro, recheio depois: derivo a de fora e multiplico pela de dentro.',
      mastery: 1,
    ),
  ];

  static const quizQuestions = <QuizQuestion>[
    QuizQuestion(
      'Qual a derivada de f(x) = x³?',
      ['3x²', 'x²', '3x', 'x³/3'],
      0,
      'A regra do tombo: o expoente desce multiplicando e diminui 1. Logo 3x².',
    ),
    QuizQuestion(
      'A derivada de uma constante é:',
      ['1', '0', 'a própria constante', 'indefinida'],
      1,
      'Constante não varia, então sua taxa de variação é 0.',
    ),
    QuizQuestion(
      'd/dx [e^x] = ?',
      ['x·e^(x-1)', 'e^x', 'ln(x)', '1/x'],
      1,
      'A exponencial natural é sua própria derivada: e^x.',
    ),
  ];

  static const themedQuestions = <QuizQuestion>[
    QuizQuestion(
      'Segundo Freud, qual instância busca a satisfação imediata dos impulsos?',
      ['Ego', 'Superego', 'Id', 'Persona'],
      2,
      'O Id opera pelo princípio do prazer, buscando satisfação imediata.',
    ),
    QuizQuestion(
      'No modelo Big Five, o "C" (Conscienciosidade) relaciona-se a:',
      ['Sociabilidade', 'Organização e disciplina', 'Ansiedade', 'Criatividade'],
      1,
      'Conscienciosidade reflete organização, responsabilidade e autodisciplina.',
    ),
  ];

  static const simulados = <SimuladoHistory>[
    SimuladoHistory('Simulado · 20q', 'há 2 dias', 8.5),
    SimuladoHistory('Simulado · 50q', 'há 5 dias', 7.2),
  ];

  // Estatísticas (gráfico semanal: alturas relativas 0-1)
  static const weekBars = <double>[0.45, 0.62, 0.38, 0.7, 0.55, 0.95, 0.6];
  static const weekLabels = <String>['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

  static const mastery = <Discipline>[
    Discipline('Cálculo I', Gw.calculo, 68, 0),
    Discipline('Algoritmos', Gw.algoritmos, 82, 0),
    Discipline('Anatomia', Gw.anatomia, 45, 0),
    Discipline('Psicologia', Gw.psicologia, 30, 0),
  ];
}
