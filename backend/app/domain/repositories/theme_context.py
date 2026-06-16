"""Porta que fornece o contexto (material) de um tema dentro de uma disciplina.

Implementações: na Etapa 3 lê o texto extraído dos materiais; na Etapa 4 passa
a usar RAG (embeddings + ChromaDB) para trazer só os trechos relevantes ao tema.
A regra híbrida (usar material se existir, senão conhecimento geral) é decidida
no caso de uso a partir do retorno desta porta.
"""
from abc import ABC, abstractmethod


class IThemeContextProvider(ABC):
    @abstractmethod
    async def get_context(self, subject_id: int, theme: str) -> str | None:
        """Retorna o contexto do tema, ou None se a disciplina não tem material."""
