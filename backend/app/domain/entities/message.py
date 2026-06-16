"""Entidade de domínio Message (mensagem do chat da disciplina)."""
from dataclasses import dataclass
from datetime import datetime


@dataclass(slots=True)
class MessageEntity:
    id: int | None
    subject_id: int
    user_id: int
    role: str  # user | assistant
    content: str
    created_at: datetime | None = None
