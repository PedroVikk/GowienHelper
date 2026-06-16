"""Value objects de IA — estruturas de entrada/saída independentes de provider."""
from dataclasses import dataclass, field
from enum import Enum


class QuestionType(str, Enum):
    MULTIPLE_CHOICE = "multiple_choice"
    TRUE_FALSE = "true_false"
    FILL_BLANK = "fill_blank"
    MATCHING = "matching"
    OPEN = "open"


class Difficulty(str, Enum):
    EASY = "easy"
    MEDIUM = "medium"
    HARD = "hard"


class QuizSource(str, Enum):
    """De onde veio o conteúdo do quiz por tema."""

    MATERIAL = "material"  # baseado no material enviado (RAG/texto)
    GENERAL = "general"  # conhecimento geral da IA travado no tema


@dataclass(slots=True)
class ThemedQuiz:
    """Resultado de um quiz por tema, com a origem usada (transparência)."""

    theme: str
    difficulty: "Difficulty"
    source: QuizSource
    questions: list["GeneratedQuestion"]


@dataclass(slots=True)
class GeneratedFlashcard:
    front: str
    back: str


@dataclass(slots=True)
class GeneratedQuestion:
    type: QuestionType
    prompt: str
    options: list[str] = field(default_factory=list)
    correct_answer: str = ""
    explanation: str = ""


@dataclass(slots=True)
class GeneratedSummary:
    short: str
    full: str
    topics: list[str] = field(default_factory=list)
    glossary: dict[str, str] = field(default_factory=dict)
    formulas: list[str] = field(default_factory=list)


@dataclass(slots=True)
class AnswerEvaluation:
    is_correct: bool
    score: float  # 0.0 - 1.0
    feedback: str


@dataclass(slots=True)
class GroundedAnswer:
    """Resposta do chat com RAG — sempre baseada no contexto fornecido."""

    answer: str
    grounded: bool  # False quando a informação não está no material
