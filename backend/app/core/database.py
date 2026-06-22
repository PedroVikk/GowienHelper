"""Configuração do SQLAlchemy: engine, sessão e Base declarativa."""
from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from app.core.config import settings

_is_sqlite = settings.database_url.startswith("sqlite")
engine = create_engine(
    settings.database_url,
    pool_pre_ping=True,
    echo=False,
    connect_args={"check_same_thread": False} if _is_sqlite else {},
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    """Base declarativa para todos os models ORM."""


def get_db() -> Generator:
    """Dependency do FastAPI que fornece uma sessão por request."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
