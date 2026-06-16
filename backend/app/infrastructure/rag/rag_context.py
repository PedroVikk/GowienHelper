"""Contexto de tema via RAG: busca os trechos relevantes no banco vetorial.

Resiliente: se o embedding ou o banco vetorial falharem (Ollama/Chroma fora do
ar, ou material ainda não indexado), cai no fallback (texto completo via SQL).
Assim o quiz por tema nunca quebra por causa da infraestrutura de IA.
"""
from loguru import logger

from app.domain.ai.ai_provider import AIProvider
from app.domain.repositories.theme_context import IThemeContextProvider
from app.domain.services.vector_store import IVectorStore

TOP_K = 6
MAX_CONTEXT_CHARS = 12000


class RagThemeContextProvider(IThemeContextProvider):
    def __init__(
        self,
        ai: AIProvider,
        vector_store: IVectorStore,
        fallback: IThemeContextProvider,
    ) -> None:
        self._ai = ai
        self._vectors = vector_store
        self._fallback = fallback

    async def get_context(self, subject_id: int, theme: str) -> str | None:
        try:
            embedding = (await self._ai.embed([theme]))[0]
            docs = self._vectors.query(subject_id, embedding, top_k=TOP_K)
            if docs:
                return "\n\n".join(docs)[:MAX_CONTEXT_CHARS]
        except Exception as exc:  # noqa: BLE001 - degrada para o fallback
            logger.warning("RAG indisponível ({}); usando fallback de texto", exc)

        return await self._fallback.get_context(subject_id, theme)
