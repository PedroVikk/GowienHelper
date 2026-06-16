"""Testes do quiz por tema: saneamento, modo híbrido e validações (offline)."""
import asyncio

import pytest

from app.application.use_cases.themed_quiz import GenerateThemedQuizUseCase
from app.core.exceptions import ValidationError
from app.domain.ai.ai_provider import AIProvider
from app.domain.ai.models import (
    AnswerEvaluation,
    Difficulty,
    GeneratedFlashcard,
    GeneratedQuestion,
    GeneratedSummary,
    GroundedAnswer,
    QuestionType,
    QuizSource,
)
from app.domain.repositories.theme_context import IThemeContextProvider
from app.infrastructure.ai.quiz_sanitize import sanitize_questions


# --------------------------------------------------------------- fakes
class FakeAIProvider(AIProvider):
    def __init__(self) -> None:
        self.last_call: dict = {}

    async def generate_summary(self, content):  # pragma: no cover - não usado
        return GeneratedSummary(short="", full="")

    async def generate_flashcards(self, content, count=10):  # pragma: no cover
        return [GeneratedFlashcard("f", "b")]

    async def generate_quiz(self, content, count=10, types=None):  # pragma: no cover
        return []

    async def generate_themed_quiz(
        self, subject, theme, count=10, difficulty=Difficulty.MEDIUM,
        types=None, context=None,
    ):
        self.last_call = {
            "subject": subject, "theme": theme, "count": count,
            "difficulty": difficulty, "context": context,
        }
        return [
            GeneratedQuestion(
                type=QuestionType.MULTIPLE_CHOICE,
                prompt=f"Pergunta sobre {theme}",
                options=["a", "b", "c", "d"],
                correct_answer="a",
                explanation="porque sim",
            )
        ]

    async def generate_mindmap(self, content):  # pragma: no cover
        return ""

    async def answer_question(self, question, context):  # pragma: no cover
        return GroundedAnswer("", grounded=False)

    async def correct_answer(self, question, expected, user_answer):  # pragma: no cover
        return AnswerEvaluation(False, 0.0, "")

    async def embed(self, texts):  # pragma: no cover
        return [[0.0] for _ in texts]


class FakeContext(IThemeContextProvider):
    def __init__(self, value: str | None) -> None:
        self._value = value

    async def get_context(self, subject_id, theme):
        return self._value


def _run(coro):
    return asyncio.run(coro)


# --------------------------------------------------------------- sanitize
def test_sanitize_drops_empty_and_no_answer():
    qs = [
        GeneratedQuestion(QuestionType.OPEN, "", correct_answer="x"),
        GeneratedQuestion(QuestionType.OPEN, "Válida?", correct_answer=""),
        GeneratedQuestion(QuestionType.OPEN, "Boa?", correct_answer="sim"),
    ]
    out = sanitize_questions(qs, count=10)
    assert len(out) == 1 and out[0].prompt == "Boa?"


def test_sanitize_dedup_and_limit():
    qs = [
        GeneratedQuestion(QuestionType.OPEN, "Mesma", correct_answer="1"),
        GeneratedQuestion(QuestionType.OPEN, "mesma", correct_answer="2"),
        GeneratedQuestion(QuestionType.OPEN, "Outra", correct_answer="3"),
        GeneratedQuestion(QuestionType.OPEN, "Terceira", correct_answer="4"),
    ]
    out = sanitize_questions(qs, count=2)
    assert len(out) == 2
    assert [q.prompt for q in out] == ["Mesma", "Outra"]


def test_sanitize_multiple_choice_requires_options():
    qs = [
        GeneratedQuestion(
            QuestionType.MULTIPLE_CHOICE, "Sem opções", options=[], correct_answer="a"
        ),
        GeneratedQuestion(
            QuestionType.MULTIPLE_CHOICE,
            "Com opções",
            options=["a", "b"],
            correct_answer="a",
        ),
    ]
    out = sanitize_questions(qs, count=10)
    assert len(out) == 1 and out[0].prompt == "Com opções"


# --------------------------------------------------------------- hybrid
def test_uses_material_when_context_exists():
    ai = FakeAIProvider()
    uc = GenerateThemedQuizUseCase(ai, FakeContext("Texto do PDF de psicologia"))
    result = _run(
        uc.execute(1, "Psicologia", "Behaviorismo", count=5, difficulty=Difficulty.HARD)
    )
    assert result.source == QuizSource.MATERIAL
    assert ai.last_call["context"] == "Texto do PDF de psicologia"
    assert ai.last_call["difficulty"] == Difficulty.HARD
    assert result.theme == "Behaviorismo"


def test_uses_general_knowledge_when_no_material():
    ai = FakeAIProvider()
    uc = GenerateThemedQuizUseCase(ai, FakeContext(None))
    result = _run(uc.execute(1, "Psicologia", "Behaviorismo"))
    assert result.source == QuizSource.GENERAL
    assert ai.last_call["context"] is None
    assert len(result.questions) == 1


def test_empty_theme_raises():
    uc = GenerateThemedQuizUseCase(FakeAIProvider(), FakeContext(None))
    with pytest.raises(ValidationError):
        _run(uc.execute(1, "Psicologia", "   "))


def test_invalid_count_raises():
    uc = GenerateThemedQuizUseCase(FakeAIProvider(), FakeContext(None))
    with pytest.raises(ValidationError):
        _run(uc.execute(1, "Psicologia", "Freud", count=999))
