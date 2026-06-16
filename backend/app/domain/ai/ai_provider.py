"""Interface AIProvider — contrato único de IA usado por toda a aplicação.

Nenhuma camada acima depende de Ollama/OpenAI/etc. diretamente: todas
conversam apenas com esta abstração. Trocar de provedor = adicionar uma nova
implementação, sem alterar regras de negócio.
"""
from abc import ABC, abstractmethod

from app.domain.ai.models import (
    AnswerEvaluation,
    Difficulty,
    GeneratedFlashcard,
    GeneratedQuestion,
    GeneratedSummary,
    GroundedAnswer,
    QuestionType,
)


class AIProvider(ABC):
    """Contrato que todo provedor de IA deve implementar."""

    @abstractmethod
    async def generate_summary(self, content: str) -> GeneratedSummary:
        """Gera resumo curto/completo, tópicos, glossário e fórmulas."""

    @abstractmethod
    async def generate_flashcards(
        self, content: str, count: int = 10
    ) -> list[GeneratedFlashcard]:
        """Gera flashcards (frente/verso) a partir do conteúdo."""

    @abstractmethod
    async def generate_quiz(
        self,
        content: str,
        count: int = 10,
        types: list[QuestionType] | None = None,
    ) -> list[GeneratedQuestion]:
        """Gera questões de quiz com explicação em cada uma."""

    @abstractmethod
    async def generate_themed_quiz(
        self,
        subject: str,
        theme: str,
        count: int = 10,
        difficulty: Difficulty = Difficulty.MEDIUM,
        types: list[QuestionType] | None = None,
        context: str | None = None,
    ) -> list[GeneratedQuestion]:
        """Gera quiz TRAVADO em um tema específico (anti-drift).

        Se ``context`` for informado, as questões devem se basear nele (material).
        Se for ``None``, usa conhecimento geral da IA — sempre restrito ao tema.
        """

    @abstractmethod
    async def generate_mindmap(self, content: str) -> str:
        """Gera um mapa mental em Markdown."""

    @abstractmethod
    async def answer_question(
        self, question: str, context: str
    ) -> GroundedAnswer:
        """Responde SOMENTE com base no contexto (RAG). Nunca inventa."""

    @abstractmethod
    async def correct_answer(
        self, question: str, expected: str, user_answer: str
    ) -> AnswerEvaluation:
        """Avalia/corrige a resposta aberta do usuário."""

    @abstractmethod
    async def embed(self, texts: list[str]) -> list[list[float]]:
        """Gera embeddings para os textos (usado pelo RAG)."""
