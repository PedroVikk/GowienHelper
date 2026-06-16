"""Teste de integração da API de Auth via TestClient (SQLite em memória)."""
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.database import Base, get_db
from app.infrastructure.db import models  # noqa: F401  (registra os models)
from app.main import app


@pytest.fixture
def client():
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

    app.dependency_overrides[get_db] = override_get_db
    yield TestClient(app)
    app.dependency_overrides.clear()


def test_register_login_me_flow(client):
    # registro
    r = client.post(
        "/api/v1/auth/register",
        json={"name": "Ana", "email": "ana@test.com", "password": "secret123"},
    )
    assert r.status_code == 201, r.text
    assert r.json()["email"] == "ana@test.com"

    # e-mail duplicado -> 409
    r = client.post(
        "/api/v1/auth/register",
        json={"name": "Ana", "email": "ana@test.com", "password": "secret123"},
    )
    assert r.status_code == 409

    # login
    r = client.post(
        "/api/v1/auth/login",
        json={"email": "ana@test.com", "password": "secret123"},
    )
    assert r.status_code == 200, r.text
    token = r.json()["access_token"]

    # rota protegida
    r = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 200, r.text
    assert r.json()["name"] == "Ana"

    # sem token -> 401
    assert client.get("/api/v1/auth/me").status_code == 401


def test_login_wrong_password(client):
    client.post(
        "/api/v1/auth/register",
        json={"name": "Bob", "email": "bob@test.com", "password": "secret123"},
    )
    r = client.post(
        "/api/v1/auth/login",
        json={"email": "bob@test.com", "password": "errada"},
    )
    assert r.status_code == 401
