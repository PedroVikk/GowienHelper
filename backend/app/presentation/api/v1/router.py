"""Agregador dos routers da API v1."""
from fastapi import APIRouter

from app.presentation.api.v1.routers import (
    auth,
    chat,
    flashcards,
    generation,
    health,
    materials,
    quiz,
    stats,
    study,
    subjects,
)

api_router = APIRouter()
api_router.include_router(health.router)
api_router.include_router(auth.router)
api_router.include_router(subjects.router)
api_router.include_router(materials.router)
api_router.include_router(quiz.router)
api_router.include_router(generation.router)
api_router.include_router(chat.router)
api_router.include_router(flashcards.router)
api_router.include_router(study.router)
api_router.include_router(stats.router)
