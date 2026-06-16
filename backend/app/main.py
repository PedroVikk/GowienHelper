"""Ponto de entrada da aplicação FastAPI."""
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from loguru import logger

from app.core.config import settings
from app.core.database import Base, engine
from app.core.exceptions import DomainError
from app.core.logging import setup_logging
from app.infrastructure.db import models  # noqa: F401  (registra os models)
from app.presentation.api.v1.router import api_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    setup_logging()
    logger.info("Iniciando {} ({})", settings.app_name, settings.app_env)
    # Em dev, cria as tabelas automaticamente. Em produção, usar Alembic.
    if settings.app_env == "development":
        Base.metadata.create_all(bind=engine)
        logger.info("Tabelas verificadas/criadas")
    yield
    logger.info("Encerrando aplicação")


app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    description="API do GowienHelper — estudos com IA local.",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(DomainError)
async def domain_error_handler(_: Request, exc: DomainError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code, content={"detail": exc.message}
    )


app.include_router(api_router, prefix=settings.api_v1_prefix)


@app.get("/", include_in_schema=False)
def root() -> dict[str, str]:
    return {"app": settings.app_name, "docs": "/docs"}
