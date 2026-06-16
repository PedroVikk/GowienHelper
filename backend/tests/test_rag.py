"""Testes do RagIndexer e do RagThemeContextProvider (com fakes, sem rede)."""
import asyncio

from app.application.use_cases.rag_indexer import RagIndexer
from app.domain.ai.ai_provider import AIProvider
from app.domain.ai.models import (
    AnswerEvaluation,
    Difficulty,
    GeneratedFlashcard,
    GeneratedQuestion,
    GeneratedSummary,
    GroundedAnswer,
)
from app.domain.entities.material import MaterialEntity
from app.domain.repositories.chunk_repository import ChunkRecord, IChunkRepository
from app.domain.repositories.theme_context import IThemeContextProvider
from app.domain.services.vector_store import IVectorStore, VectorItem
from app.infrastructure.rag.rag_context import RagThemeContextProvider


class FakeAI(AIProvider):
    def __init__(self, embed_fail=False):
        self.embed_fail = embed_fail

    async def generate_summary(self, content):
        return GeneratedSummary("", "")

    async def generate_flashcards(self, content, count=10):
        return [GeneratedFlashcard("f", "b")]

    async def generate_quiz(self, content, count=10, types=None):
        return []

    async def generate_themed_quiz(self, *a, **k):
        return []

    async def generate_mindmap(self, content):
        return ""

    async def answer_question(self, question, context):
        return GroundedAnswer("", grounded=False)

    async def correct_answer(self, question, expected, user_answer):
        return AnswerEvaluation(False, 0.0, "")

    async def embed(self, texts):
        if self.embed_fail:
            raise RuntimeError("ollama down")
        return [[float(len(t)), 1.0] for t in texts]


class FakeVectorStore(IVectorStore):
    def __init__(self, query_result=None):
        self.added: list[VectorItem] = []
        self.deleted: list[tuple[int, int]] = []
        self._query_result = query_result if query_result is not None else []

    def add(self, subject_id, items):
        self.added.extend(items)

    def query(self, subject_id, embedding, top_k=5):
        return list(self._query_result)

    def delete_material(self, subject_id, material_id):
        self.deleted.append((subject_id, material_id))


class FakeChunks(IChunkRepository):
    def __init__(self):
        self.records: list[ChunkRecord] = []
        self.deleted: list[int] = []

    def add_many(self, chunks):
        self.records.extend(chunks)

    def delete_by_material(self, material_id):
        self.deleted.append(material_id)


class FakeFallback(IThemeContextProvider):
    def __init__(self, value):
        self.value = value
        self.called = False

    async def get_context(self, subject_id, theme):
        self.called = True
        return self.value


def _material(text):
    return MaterialEntity(
        id=7, subject_id=3, filename="a.txt", file_type="txt",
        file_path="/x", extracted_text=text, status="extracted",
    )


# ----------------------------------------------------------------- indexer
def test_indexer_creates_chunks_and_vectors():
    ai, vectors, chunks = FakeAI(), FakeVectorStore(), FakeChunks()
    n = asyncio.run(
        RagIndexer(ai, chunks, vectors).index(
            _material("Texto longo. " * 200)
        )
    )
    assert n > 0
    assert len(vectors.added) == n == len(chunks.records)
    # ids casam entre vetor e chunk
    assert vectors.added[0].id == chunks.records[0].vector_id == "7_0"
    assert vectors.added[0].material_id == 7


def test_indexer_empty_text_noop():
    ai, vectors, chunks = FakeAI(), FakeVectorStore(), FakeChunks()
    n = asyncio.run(RagIndexer(ai, chunks, vectors).index(_material("")))
    assert n == 0 and vectors.added == [] and chunks.records == []


def test_indexer_remove():
    ai, vectors, chunks = FakeAI(), FakeVectorStore(), FakeChunks()
    asyncio.run(RagIndexer(ai, chunks, vectors).remove(_material("x")))
    assert vectors.deleted == [(3, 7)]
    assert chunks.deleted == [7]


# ----------------------------------------------------------------- context
def test_context_uses_vector_results():
    provider = RagThemeContextProvider(
        FakeAI(),
        FakeVectorStore(query_result=["trecho A", "trecho B"]),
        FakeFallback("nao deveria usar"),
    )
    ctx = asyncio.run(provider.get_context(3, "Behaviorismo"))
    assert "trecho A" in ctx and "trecho B" in ctx


def test_context_falls_back_when_no_vectors():
    fb = FakeFallback("texto completo do material")
    provider = RagThemeContextProvider(FakeAI(), FakeVectorStore([]), fb)
    ctx = asyncio.run(provider.get_context(3, "Tema"))
    assert ctx == "texto completo do material" and fb.called


def test_context_falls_back_when_embed_fails():
    fb = FakeFallback("fallback")
    provider = RagThemeContextProvider(
        FakeAI(embed_fail=True), FakeVectorStore(["x"]), fb
    )
    ctx = asyncio.run(provider.get_context(3, "Tema"))
    assert ctx == "fallback" and fb.called
