"""Implementação SQLAlchemy do repositório de mensagens."""
from sqlalchemy import delete, func, select
from sqlalchemy.orm import Session

from app.domain.entities.message import MessageEntity
from app.domain.repositories.message_repository import IMessageRepository
from app.infrastructure.db.models.study import Message


def _to_entity(m: Message) -> MessageEntity:
    return MessageEntity(
        id=m.id,
        subject_id=m.subject_id,
        user_id=m.user_id,
        role=m.role,
        content=m.content,
        created_at=m.created_at,
    )


class SqlMessageRepository(IMessageRepository):
    def __init__(self, db: Session) -> None:
        self._db = db

    def add(self, message: MessageEntity) -> MessageEntity:
        model = Message(
            subject_id=message.subject_id,
            user_id=message.user_id,
            role=message.role,
            content=message.content,
        )
        self._db.add(model)
        self._db.commit()
        self._db.refresh(model)
        return _to_entity(model)

    def list_by_subject(
        self, subject_id: int, limit: int, offset: int
    ) -> tuple[list[MessageEntity], int]:
        base = select(Message).where(Message.subject_id == subject_id)
        total = self._db.scalar(
            select(func.count()).select_from(base.subquery())
        )
        rows = self._db.scalars(
            base.order_by(Message.created_at, Message.id).limit(limit).offset(offset)
        ).all()
        return [_to_entity(r) for r in rows], int(total or 0)

    def delete_by_subject(self, subject_id: int) -> None:
        self._db.execute(delete(Message).where(Message.subject_id == subject_id))
        self._db.commit()
