"""Implementação de AIProvider usando Ollama (modelo local, ex.: qwen3:8b)."""
import httpx
from loguru import logger

from app.core.config import settings
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
from app.infrastructure.ai.json_utils import extract_json, strip_think
from app.infrastructure.ai.quiz_sanitize import sanitize_questions


class OllamaProvider(AIProvider):
    """Provedor de IA local via API HTTP do Ollama."""

    def __init__(
        self,
        base_url: str | None = None,
        model: str | None = None,
        embed_model: str | None = None,
        timeout: float = 300.0,
    ) -> None:
        self._base_url = (base_url or settings.ollama_base_url).rstrip("/")
        self._model = model or settings.ollama_model
        self._embed_model = embed_model or settings.ollama_embed_model
        self._timeout = timeout

    # ---------------------------------------------------------------- core
    async def _generate(self, prompt: str, temperature: float = 0.3) -> str:
        """Chama /api/generate e retorna o texto (sem blocos de raciocínio)."""
        payload = {
            "model": self._model,
            "prompt": prompt,
            "stream": False,
            "think": False,
            "options": {"temperature": temperature},
        }
        async with httpx.AsyncClient(timeout=self._timeout) as client:
            resp = await client.post(f"{self._base_url}/api/generate", json=payload)
            resp.raise_for_status()
            data = resp.json()
        return strip_think(data.get("response", ""))

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
        """Converte o JSON do modelo em GeneratedQuestion (tolerante a ruído)."""
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
        self,
        content: str,
        count: int = 10,
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
        self,
        subject: str,
        theme: str,
        count: int = 10,
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
        # temperatura baixa reduz o "drift" do tema
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

    # ------------------------------------------------------------ embeddings
    async def embed(self, texts: list[str]) -> list[list[float]]:
        embeddings: list[list[float]] = []
        async with httpx.AsyncClient(timeout=self._timeout) as client:
            for text in texts:
                resp = await client.post(
                    f"{self._base_url}/api/embeddings",
                    json={"model": self._embed_model, "prompt": text},
                )
                resp.raise_for_status()
                embeddings.append(resp.json().get("embedding", []))
        return embeddings
