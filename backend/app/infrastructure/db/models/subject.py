"""Model de disciplina (subject)."""
from datetime import date

from sqlalchemy import Date, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.infrastructure.db.models.base import TimestampMixin


class Subject(Base, TimestampMixin):
    __tablename__ = "subjects"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )

    name: Mapped[str] = mapped_column(String(150))
    color: Mapped[str] = mapped_column(String(20), default="#6750A4")
    icon: Mapped[str] = mapped_column(String(50), default="school")
    professor: Mapped[str | None] = mapped_column(String(150), nullable=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    exam_date: Mapped[date | None] = mapped_column(Date, nullable=True)

    user: Mapped["User"] = relationship(back_populates="subjects")  # noqa: F821
    materials: Mapped[list["Material"]] = relationship(  # noqa: F821
        back_populates="subject", cascade="all, delete-orphan"
    )
