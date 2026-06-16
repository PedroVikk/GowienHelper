"""Casos de uso do chat por disciplina (RAG, responde só pelo material)."""
from app.core.exceptions import NotFoundError, ValidationError
from app.domain.ai.ai_provider import AIProvider
from app.domain.ai.models import GroundedAnswer
from app.domain.entities.message import MessageEntity
from app.domain.repositories.message_repository import IMessageRepository
from app.domain.repositories.subject_repository import ISubjectRepository
from app.domain.repositories.theme_context import IThemeContextProvider


def _ensure_subject(
    subjects: ISubjectRepository, subject_id: int, user_id: int
) -> None:
    subject = subjects.get_by_id(subject_id)
    if subject is None or subject.user_id != user_id:
        raise NotFoundError("Disciplina não encontrada.")


class AnswerChatUseCase:
    """Responde uma pergunta usando SOMENTE o material (RAG) e salva o histórico."""

    def __init__(
        self,
        subjects: ISubjectRepository,
        messages: IMessageRepository,
        ai: AIProvider,
        context: IThemeContextProvider,
    ) -> None:
        self._subjects = subjects
        self._messages = messages
        self._ai = ai
        self._context = context

    async def execute(
        self, user_id: int, subject_id: int, question: str
    ) -> GroundedAnswer:
        _ensure_subject(self._subjects, subject_id, user_id)
        question = question.strip()
        if not question:
            raise ValidationError("Digite uma pergunta.")

        context = await self._context.get_context(subject_id, question)
        answer = await self._ai.answer_question(question, context or "")

        self._messages.add(
            MessageEntity(None, subject_id, user_id, "user", question)
        )
        self._messages.add(
            MessageEntity(None, subject_id, user_id, "assistant", answer.answer)
        )
        return answer


class ListChatHistoryUseCase:
    def __init__(
        self, subjects: ISubjectRepository, messages: IMessageRepository
    ) -> None:
        self._subjects = subjects
        self._messages = messages

    def execute(
        self, user_id: int, subject_id: int, limit: int, offset: int
    ) -> tuple[list[MessageEntity], int]:
        _ensure_subject(self._subjects, subject_id, user_id)
        return self._messages.list_by_subject(subject_id, limit, offset)


class ClearChatUseCase:
    def __init__(
        self, subjects: ISubjectRepository, messages: IMessageRepository
    ) -> None:
        self._subjects = subjects
        self._messages = messages

    def execute(self, user_id: int, subject_id: int) -> None:
        _ensure_subject(self._subjects, subject_id, user_id)
        self._messages.delete_by_subject(subject_id)
