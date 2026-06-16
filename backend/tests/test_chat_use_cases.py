"""Testes unitários do caso de uso de chat (grounding + persistência)."""
import asyncio

import pytest

from app.application.use_cases.chat import AnswerChatUseCase
from app.core.exceptions import NotFoundError, ValidationError
from app.domain.ai.models import GroundedAnswer
from app.domain.entities.message import MessageEntity
from app.domain.entities.subject import SubjectEntity
from app.domain.repositories.message_repository import IMessageRepository
from app.domain.repositories.subject_repository import ISubjectRepository
from app.domain.repositories.theme_context import IThemeContextProvider


class FakeSubjects(ISubjectRepository):
    def __init__(self, owner=1):
        self._s = SubjectEntity(id=1, user_id=owner, name="X")

    def create(self, s):  # pragma: no cover
        return s

    def get_by_id(self, sid):
        return self._s if sid == 1 else None

    def list_by_user(self, *a):  # pragma: no cover
        return [], 0

    def update(self, s):  # pragma: no cover
        return s

    def delete(self, sid):  # pragma: no cover
        ...


class FakeMessages(IMessageRepository):
    def __init__(self):
        self.added: list[MessageEntity] = []

    def add(self, m):
        self.added.append(m)
        return m

    def list_by_subject(self, sid, limit, offset):  # pragma: no cover
        return self.added, len(self.added)

    def delete_by_subject(self, sid):  # pragma: no cover
        self.added.clear()


class FakeContext(IThemeContextProvider):
    def __init__(self, value):
        self.value = value

    async def get_context(self, subject_id, theme):
        return self.value


class FakeAI:
    async def answer_question(self, question, context):
        if not context.strip():
            return GroundedAnswer("não está presente", grounded=False)
        return GroundedAnswer(f"resp: {question}", grounded=True)


def _uc(context_value, owner=1):
    return AnswerChatUseCase(
        FakeSubjects(owner), FakeMessages(), FakeAI(), FakeContext(context_value)
    )


def test_answers_and_persists_two_messages():
    msgs = FakeMessages()
    uc = AnswerChatUseCase(
        FakeSubjects(), msgs, FakeAI(), FakeContext("material relevante")
    )
    ans = asyncio.run(uc.execute(1, 1, "pergunta?"))
    assert ans.grounded is True
    assert [m.role for m in msgs.added] == ["user", "assistant"]
    assert msgs.added[0].content == "pergunta?"


def test_refuses_when_no_context():
    ans = asyncio.run(_uc(None).execute(1, 1, "pergunta?"))
    assert ans.grounded is False


def test_empty_question_raises():
    with pytest.raises(ValidationError):
        asyncio.run(_uc("ctx").execute(1, 1, "   "))


def test_other_user_raises():
    with pytest.raises(NotFoundError):
        asyncio.run(_uc("ctx", owner=999).execute(1, 1, "pergunta?"))
