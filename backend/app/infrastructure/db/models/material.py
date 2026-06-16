"""Models de material enviado e seus chunks (para RAG)."""
from sqlalchemy import ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.infrastructure.db.models.base import TimestampMixin


class Material(Base, TimestampMixin):
    __tablename__ = "materials"

    id: Mapped[int] = mapped_column(primary_key=True)
    subject_id: Mapped[int] = mapped_column(
        ForeignKey("subjects.id", ondelete="CASCADE"), index=True
    )

    filename: Mapped[str] = mapped_column(String(255))
    file_type: Mapped[str] = mapped_column(String(20))  # pdf, docx, txt, md, image
    file_path: Mapped[str] = mapped_column(String(500))
    extracted_text: Mapped[str | None] = mapped_column(Text, nullable=True)
    # pending | extracted | processed | failed
    status: Mapped[str] = mapped_column(String(20), default="pending")

    subject: Mapped["Subject"] = relationship(  # noqa: F821
        back_populates="materials"
    )
    chunks: Mapped[list["Chunk"]] = relationship(
        back_populates="material", cascade="all, delete-orphan"
    )


class Chunk(Base, TimestampMixin):
    __tablename__ = "chunks"

    id: Mapped[int] = mapped_column(primary_key=True)
    material_id: Mapped[int] = mapped_column(
        ForeignKey("materials.id", ondelete="CASCADE"), index=True
    )

    index: Mapped[int] = mapped_column(Integer)
    content: Mapped[str] = mapped_column(Text)
    # id do vetor no ChromaDB
    vector_id: Mapped[str | None] = mapped_column(String(64), nullable=True)

    material: Mapped["Material"] = relationship(back_populates="chunks")
