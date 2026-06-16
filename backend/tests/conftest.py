"""Fixtures compartilhadas para os testes de API (SQLite + auth + IA falsa)."""
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.database import Base, get_db
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
from app.infrastructure.ai.factory import get_ai_provider
from app.infrastructure.db import models  # noqa: F401  (registra os models)
from app.infrastructure.storage.local_storage import LocalFileStorage
from app.main import app
from app.presentation.api.deps import get_file_storage


class StubAIProvider(AIProvider):
    """IA determinística para testes de API (sem rede)."""

    async def generate_summary(self, content):
        return GeneratedSummary(
            short="resumo curto",
            full="resumo completo do material",
            topics=["Tópico 1", "Tópico 2"],
            glossary={"termo": "definição"},
            formulas=[],
        )

    async def generate_flashcards(self, content, count=10):
        return [
            GeneratedFlashcard(f"frente {i}", f"verso {i}") for i in range(count)
        ]

    async def generate_quiz(self, content, count=10, types=None):
        return [
            GeneratedQuestion(
                type=QuestionType.MULTIPLE_CHOICE,
                prompt=f"Questão {i}",
                options=["a", "b", "c", "d"],
                correct_answer="a",
                explanation="explicação",
            )
            for i in range(count)
        ]

    async def generate_themed_quiz(
        self, subject, theme, count=10, difficulty=Difficulty.MEDIUM,
        types=None, context=None,
    ):
        return [
            GeneratedQuestion(
                type=QuestionType.MULTIPLE_CHOICE,
                prompt=f"O que é {theme}?",
                options=["a", "b", "c", "d"],
                correct_answer="a",
                explanation="explicação",
            )
        ]

    async def generate_mindmap(self, content):
        return "# Mapa\n- nó 1\n- nó 2"

    async def answer_question(self, question, context):
        if not context.strip():
            return GroundedAnswer(
                "Essa informação não está presente no material enviado.",
                grounded=False,
            )
        return GroundedAnswer(
            f"Com base no material, sobre '{question}'.", grounded=True
        )

    async def correct_answer(self, question, expected, user_answer):
        ok = user_answer.strip().lower() == expected.strip().lower()
        return AnswerEvaluation(ok, 1.0 if ok else 0.0, "feedback da IA")

    async def embed(self, texts):
        return [[0.0] for _ in texts]


@pytest.fixture
def client(tmp_path):
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(bind=engine)
    TestingSession = sessionmaker(bind=engine, autoflush=False, autocommit=False)

    def override_get_db():
        db = TestingSession()
        try:
            yield db
        finally:
            db.close()

    storage = LocalFileStorage(base_dir=str(tmp_path / "storage"))
    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[get_ai_provider] = lambda: StubAIProvider()
    app.dependency_overrides[get_file_storage] = lambda: storage
    yield TestClient(app)
    app.dependency_overrides.clear()


@pytest.fixture
def auth_headers(client):
    client.post(
        "/api/v1/auth/register",
        json={"name": "Ana", "email": "ana@test.com", "password": "secret123"},
    )
    r = client.post(
        "/api/v1/auth/login",
        json={"email": "ana@test.com", "password": "secret123"},
    )
    return {"Authorization": f"Bearer {r.json()['access_token']}"}
