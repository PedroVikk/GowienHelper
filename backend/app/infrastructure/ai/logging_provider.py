"""Decorator de AIProvider que registra cada chamada na tabela ai_logs.

Envolve qualquer AIProvider, cronometra a chamada e grava um AiLog (best-effort:
falha de log nunca quebra a geração). Alimenta o painel de IA (/ai).
"""
import time
from typing import Any, Awaitable, Callable

from loguru import logger

from app.core.config import settings
from app.core.database import SessionLocal
from app.domain.ai.ai_provider import AIProvider
from app.domain.ai.models import (
    AnswerEvaluation,
    Difficulty,
    GeneratedFlashcard,
    GeneratedQuestion,
    GeneratedSummary,
    GroundedAnswer,
    QuestionType,
)
from app.infrastructure.db.models.ai_log import AiLog


def _record(operation: str, model: str, duration_ms: int, ok: bool,
            chars_out: int, detail: str | None) -> None:
    try:
        with SessionLocal() as db:
            db.add(AiLog(
                operation=operation,
                model=model,
                duration_ms=duration_ms,
                ok=ok,
                chars_out=chars_out,
                detail=(detail or "")[:300] or None,
            ))
            db.commit()
    except Exception as e:  # noqa: BLE001
        logger.warning("Falha ao registrar AiLog: {}", e)


def _size(result: Any) -> int:
    try:
        if isinstance(result, list):
            return sum(len(str(x)) for x in result)
        return len(str(result))
    except Exception:  # noqa: BLE001
        return 0


class LoggingAIProvider(AIProvider):
    def __init__(self, inner: AIProvider) -> None:
        self._inner = inner

    async def _run(
        self, operation: str, call: Callable[[], Awaitable[Any]]
    ) -> Any:
        start = time.perf_counter()
        ok = True
        detail = None
        result = None
        try:
            result = await call()
            return result
        except Exception as e:  # noqa: BLE001
            ok = False
            detail = f"{type(e).__name__}: {e}"
            raise
        finally:
            ms = int((time.perf_counter() - start) * 1000)
            model = getattr(self._inner, "_model", settings.ollama_model)
            _record(operation, model, ms, ok, _size(result), detail)

    async def generate_summary(self, content: str) -> GeneratedSummary:
        return await self._run(
            "summary", lambda: self._inner.generate_summary(content))

    async def generate_flashcards(
        self, content: str, count: int = 10
    ) -> list[GeneratedFlashcard]:
        return await self._run(
            "flashcards",
            lambda: self._inner.generate_flashcards(content, count=count))

    async def generate_quiz(
        self, content: str, count: int = 10,
        types: list[QuestionType] | None = None,
    ) -> list[GeneratedQuestion]:
        return await self._run(
            "quiz",
            lambda: self._inner.generate_quiz(content, count=count, types=types))

    async def generate_themed_quiz(
        self, subject: str, theme: str, count: int = 10,
        difficulty: Difficulty = Difficulty.MEDIUM,
        types: list[QuestionType] | None = None,
        context: str | None = None,
    ) -> list[GeneratedQuestion]:
        return await self._run(
            "themed_quiz",
            lambda: self._inner.generate_themed_quiz(
                subject, theme, count=count, difficulty=difficulty,
                types=types, context=context))

    async def generate_mindmap(self, content: str) -> str:
        return await self._run(
            "mindmap", lambda: self._inner.generate_mindmap(content))

    async def answer_question(
        self, question: str, context: str
    ) -> GroundedAnswer:
        return await self._run(
            "answer", lambda: self._inner.answer_question(question, context))

    async def correct_answer(
        self, question: str, expected: str, user_answer: str
    ) -> AnswerEvaluation:
        return await self._run(
            "correct",
            lambda: self._inner.correct_answer(question, expected, user_answer))

    async def embed(self, texts: list[str]) -> list[list[float]]:
        return await self._run("embed", lambda: self._inner.embed(texts))
