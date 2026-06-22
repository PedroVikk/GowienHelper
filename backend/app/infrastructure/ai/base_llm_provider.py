"""Base comum dos provedores LLM (Ollama, Gemini, ...).

Concentra a orquestração de prompts e o parsing de JSON; cada provedor concreto
só implementa `_generate` (texto) e `embed` (embeddings).
"""
from abc import abstractmethod

from loguru import logger

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
from app.infrastructure.ai import prompts
from app.infrastructure.ai.json_utils import extract_json
from app.infrastructure.ai.quiz_sanitize import sanitize_questions


class BaseLLMProvider(AIProvider):
    """Implementa todas as operações de IA em termos de `_generate`/`embed`."""

    @abstractmethod
    async def _generate(self, prompt: str, temperature: float = 0.3) -> str:
        """Gera texto a partir de um prompt (sem blocos de raciocínio)."""

    # ----------------------------------------------------------- summaries
    async def generate_summary(self, content: str) -> GeneratedSummary:
        raw = await self._generate(prompts.SUMMARY_PROMPT.format(content=content))
        try:
            data = extract_json(raw)
        except ValueError:
            logger.warning("Resumo: JSON inválido, usando fallback de texto puro")
            return GeneratedSummary(short=raw[:300], full=raw)
        return GeneratedSummary(
            short=data.get("short", ""),
            full=data.get("full", ""),
            topics=data.get("topics", []),
            glossary=data.get("glossary", {}),
            formulas=data.get("formulas", []),
        )

    async def generate_flashcards(
        self, content: str, count: int = 10
    ) -> list[GeneratedFlashcard]:
        raw = await self._generate(
            prompts.FLASHCARDS_PROMPT.format(content=content, count=count)
        )
        data = extract_json(raw)
        return [
            GeneratedFlashcard(front=i.get("front", ""), back=i.get("back", ""))
            for i in data
            if i.get("front")
        ]

    @staticmethod
    def _parse_questions(raw: str) -> list[GeneratedQuestion]:
        data = extract_json(raw)
        questions: list[GeneratedQuestion] = []
        for i in data:
            try:
                qtype = QuestionType(i.get("type", "multiple_choice"))
            except ValueError:
                qtype = QuestionType.MULTIPLE_CHOICE
            questions.append(
                GeneratedQuestion(
                    type=qtype,
                    prompt=i.get("prompt", ""),
                    options=i.get("options", []) or [],
                    correct_answer=str(i.get("correct_answer", "")),
                    explanation=i.get("explanation", ""),
                )
            )
        return questions

    async def generate_quiz(
        self, content: str, count: int = 10,
        types: list[QuestionType] | None = None,
    ) -> list[GeneratedQuestion]:
        type_names = ", ".join(t.value for t in types) if types else "todos"
        raw = await self._generate(
            prompts.QUIZ_PROMPT.format(
                content=content, count=count, types=type_names
            )
        )
        return self._parse_questions(raw)

    async def generate_themed_quiz(
        self, subject: str, theme: str, count: int = 10,
        difficulty: Difficulty = Difficulty.MEDIUM,
        types: list[QuestionType] | None = None,
        context: str | None = None,
    ) -> list[GeneratedQuestion]:
        type_names = ", ".join(t.value for t in types) if types else "todos"
        if context and context.strip():
            source_rule = prompts.THEMED_SOURCE_RULE_MATERIAL
            context_block = f"\nMATERIAL:\n{context}"
        else:
            source_rule = prompts.THEMED_SOURCE_RULE_GENERAL
            context_block = ""

        prompt = prompts.THEMED_QUIZ_PROMPT.format(
            subject=subject,
            theme=theme,
            difficulty=prompts.DIFFICULTY_GUIDE[difficulty.value],
            count=count,
            types=type_names,
            source_rule=source_rule,
            context_block=context_block,
        )
        raw = await self._generate(prompt, temperature=0.2)
        return sanitize_questions(self._parse_questions(raw), count)

    async def generate_mindmap(self, content: str) -> str:
        raw = await self._generate(prompts.MINDMAP_PROMPT.format(content=content))
        return raw.strip()

    # ------------------------------------------------------------ RAG / chat
    async def answer_question(
        self, question: str, context: str
    ) -> GroundedAnswer:
        if not context.strip():
            return GroundedAnswer(prompts.GROUNDING_REFUSAL, grounded=False)
        raw = await self._generate(
            prompts.ANSWER_PROMPT.format(context=context, question=question)
        )
        answer = raw.strip()
        grounded = prompts.GROUNDING_REFUSAL.lower() not in answer.lower()
        return GroundedAnswer(answer=answer, grounded=grounded)

    async def correct_answer(
        self, question: str, expected: str, user_answer: str
    ) -> AnswerEvaluation:
        raw = await self._generate(
            prompts.CORRECTION_PROMPT.format(
                question=question, expected=expected, user_answer=user_answer
            )
        )
        try:
            data = extract_json(raw)
        except ValueError:
            return AnswerEvaluation(is_correct=False, score=0.0, feedback=raw)
        return AnswerEvaluation(
            is_correct=bool(data.get("is_correct", False)),
            score=float(data.get("score", 0.0)),
            feedback=data.get("feedback", ""),
        )
