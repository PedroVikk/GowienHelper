"""Implementação de IVectorStore usando ChromaDB.

O import do chromadb é lazy (dentro dos métodos) para que a aplicação suba
mesmo sem o pacote/servidor disponível — nesse caso o chamador trata o erro e
cai no fallback (texto completo). Uma coleção por disciplina.
"""
from app.core.config import settings
from app.domain.services.vector_store import IVectorStore, VectorItem


class ChromaVectorStore(IVectorStore):
    def __init__(self, host: str | None = None, port: int | None = None) -> None:
        self._host = host or settings.chroma_host
        self._port = port or settings.chroma_port
        self._client = None

    def _get_client(self):
        if self._client is None:
            import chromadb

            self._client = chromadb.HttpClient(host=self._host, port=self._port)
        return self._client

    def _collection(self, subject_id: int):
        # embeddings são fornecidos por nós (Ollama); sem embedding function aqui
        return self._get_client().get_or_create_collection(
            name=f"subject_{subject_id}", metadata={"hnsw:space": "cosine"}
        )

    def add(self, subject_id: int, items: list[VectorItem]) -> None:
        if not items:
            return
        self._collection(subject_id).upsert(
            ids=[i.id for i in items],
            embeddings=[i.embedding for i in items],
            documents=[i.document for i in items],
            metadatas=[{"material_id": i.material_id} for i in items],
        )

    def query(
        self, subject_id: int, embedding: list[float], top_k: int = 5
    ) -> list[str]:
        result = self._collection(subject_id).query(
            query_embeddings=[embedding], n_results=top_k
        )
        docs = result.get("documents") or [[]]
        return docs[0] if docs else []

    def delete_material(self, subject_id: int, material_id: int) -> None:
        self._collection(subject_id).delete(where={"material_id": material_id})
