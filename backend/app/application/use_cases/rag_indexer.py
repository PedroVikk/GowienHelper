"""RagIndexer: transforma o texto de um material em vetores pesquisáveis."""
from app.domain.ai.ai_provider import AIProvider
from app.domain.entities.material import MaterialEntity
from app.domain.repositories.chunk_repository import (
    ChunkRecord,
    IChunkRepository,
)
from app.domain.services.indexer import IMaterialIndexer
from app.domain.services.vector_store import IVectorStore, VectorItem
from app.infrastructure.rag.chunking import chunk_text


class RagIndexer(IMaterialIndexer):
    def __init__(
        self,
        ai: AIProvider,
        chunks: IChunkRepository,
        vector_store: IVectorStore,
    ) -> None:
        self._ai = ai
        self._chunks = chunks
        self._vectors = vector_store

    async def index(self, material: MaterialEntity) -> int:
        text = material.extracted_text or ""
        pieces = chunk_text(text)
        if not pieces:
            return 0

        embeddings = await self._ai.embed(pieces)

        items: list[VectorItem] = []
        records: list[ChunkRecord] = []
        for i, (piece, emb) in enumerate(zip(pieces, embeddings)):
            vector_id = f"{material.id}_{i}"
            items.append(
                VectorItem(
                    id=vector_id,
                    embedding=emb,
                    document=piece,
                    material_id=material.id,
                )
            )
            records.append(
                ChunkRecord(
                    material_id=material.id,
                    index=i,
                    content=piece,
                    vector_id=vector_id,
                )
            )

        self._vectors.add(material.subject_id, items)
        self._chunks.add_many(records)
        return len(pieces)

    async def remove(self, material: MaterialEntity) -> None:
        self._vectors.delete_material(material.subject_id, material.id)
        self._chunks.delete_by_material(material.id)
