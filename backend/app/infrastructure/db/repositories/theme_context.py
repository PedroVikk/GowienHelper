"""Implementação da porta de contexto de tema baseada no texto dos materiais.

Versão da Etapa 2/3 (texto extraído completo). Na Etapa 4 será substituída por
uma versão com RAG (embeddings + ChromaDB) que traz só os trechos relevantes.
"""
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.domain.repositories.theme_context import IThemeContextProvider
from app.infrastructure.db.models.material import Material

# Limite de caracteres enviados ao modelo (evita estourar a janela de contexto).
MAX_CONTEXT_CHARS = 12000


class SqlThemeContextProvider(IThemeContextProvider):
    def __init__(self, db: Session) -> None:
        self._db = db

    async def get_context(self, subject_id: int, theme: str) -> str | None:
        texts = self._db.scalars(
            select(Material.extracted_text).where(
                Material.subject_id == subject_id,
                Material.extracted_text.is_not(None),
            )
        ).all()
        if not texts:
            return None
        joined = "\n\n".join(t for t in texts if t)
        return joined[:MAX_CONTEXT_CHARS] or None
