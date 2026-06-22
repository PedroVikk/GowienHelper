"""Registro de cada chamada à IA (para o painel de uso)."""
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class AiLog(Base):
    __tablename__ = "ai_logs"

    id: Mapped[int] = mapped_column(primary_key=True)
    operation: Mapped[str] = mapped_column(String(40), index=True)
    model: Mapped[str] = mapped_column(String(80))
    duration_ms: Mapped[int] = mapped_column(Integer, default=0)
    ok: Mapped[bool] = mapped_column(Boolean, default=True)
    chars_out: Mapped[int] = mapped_column(Integer, default=0)
    detail: Mapped[str | None] = mapped_column(String(300), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), index=True
    )
