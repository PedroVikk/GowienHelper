"""Casos de uso de geração de conteúdo por IA a partir do material."""
from app.core.exceptions import NotFoundError, ValidationError
from app.domain.ai.ai_provider import AIProvider
from app.domain.ai.models import GeneratedSummary, QuestionType
from app.domain.entities.flashcard import FlashcardEntity
from app.domain.entities.quiz import QuestionEntity, QuizEntity
from app.domain.entities.subject import SubjectEntity
from app.domain.repositories.flashcard_repository import IFlashcardRepository
from app.domain.repositories.material_repository import IMaterialRepository
from app.domain.repositories.quiz_repository import IQuizRepository
from app.domain.repositories.subject_repository import ISubjectRepository

MAX_CONTENT_CHARS = 16000


def _subject_or_404(
    subjects: ISubjectRepository, subject_id: int, user_id: int
) -> SubjectEntity:
    subject = subjects.get_by_id(subject_id)
    if subject is None or subject.user_id != user_id:
        raise NotFoundError("Disciplina não encontrada.")
    return subject


def _subject_content(
    materials: IMaterialRepository, subject_id: int
) -> str:
    texts = [
        m.extracted_text
        for m in materials.list_by_subject(subject_id)
        if m.extracted_text
    ]
    content = "\n\n".join(texts).strip()
    if not content:
        raise ValidationError(
            "Nenhum material com texto. Envie um material antes de gerar conteúdo."
        )
    return content[:MAX_CONTENT_CHARS]


class GenerateSummaryUseCase:
    def __init__(
        self,
        subjects: ISubjectRepository,
        materials: IMaterialRepository,
        ai: AIProvider,
    ) -> None:
        self._subjects = subjects
        self._materials = materials
        self._ai = ai

    async def execute(self, user_id: int, subject_id: int) -> GeneratedSummary:
        _subject_or_404(self._subjects, subject_id, user_id)
        content = _subject_content(self._materials, subject_id)
        return await self._ai.generate_summary(content)


class GenerateMindmapUseCase:
    def __init__(
        self,
        subjects: ISubjectRepository,
        materials: IMaterialRepository,
        ai: AIProvider,
    ) -> None:
        self._subjects = subjects
        self._materials = materials
        self._ai = ai

    async def execute(self, user_id: int, subject_id: int) -> str:
        _subject_or_404(self._subjects, subject_id, user_id)
        content = _subject_content(self._materials, subject_id)
        return await self._ai.generate_mindmap(content)


class GenerateFlashcardsUseCase:
    def __init__(
        self,
        subjects: ISubjectRepository,
        materials: IMaterialRepository,
        ai: AIProvider,
        flashcards: IFlashcardRepository,
    ) -> None:
        self._subjects = subjects
        self._materials = materials
        self._ai = ai
        self._flashcards = flashcards

    async def execute(
        self, user_id: int, subject_id: int, count: int = 10
    ) -> list[FlashcardEntity]:
        _subject_or_404(self._subjects, subject_id, user_id)
        content = _subject_content(self._materials, subject_id)
        generated = await self._ai.generate_flashcards(content, count=count)
        entities = [
            FlashcardEntity(
                id=None, subject_id=subject_id, front=g.front, back=g.back
            )
            for g in generated
            if g.front and g.back
        ]
        return self._flashcards.add_many(entities)


class GenerateQuizUseCase:
    def __init__(
        self,
        subjects: ISubjectRepository,
        materials: IMaterialRepository,
        ai: AIProvider,
        quizzes: IQuizRepository,
    ) -> None:
        self._subjects = subjects
        self._materials = materials
        self._ai = ai
        self._quizzes = quizzes

    async def execute(
        self,
        user_id: int,
        subject_id: int,
        count: int = 10,
        types: list[QuestionType] | None = None,
    ) -> QuizEntity:
        _subject_or_404(self._subjects, subject_id, user_id)
        content = _subject_content(self._materials, subject_id)
        generated = await self._ai.generate_quiz(content, count=count, types=types)
        if not generated:
            raise ValidationError("A IA não retornou questões. Tente novamente.")
        quiz = QuizEntity(
            id=None,
            subject_id=subject_id,
            title="Quiz do material",
            kind="quiz",
            questions=[
                QuestionEntity(
                    id=None,
                    type=q.type.value,
                    prompt=q.prompt,
                    options=q.options,
                    correct_answer=q.correct_answer,
                    explanation=q.explanation,
                )
                for q in generated
            ],
        )
        return self._quizzes.create(quiz)
