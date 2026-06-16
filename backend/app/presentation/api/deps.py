"""Dependências do FastAPI: wiring de repositórios, IA e usuário autenticado."""
from typing import Annotated

from fastapi import Depends
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.core.exceptions import UnauthorizedError
from app.core.security import decode_access_token
from app.application.use_cases.rag_indexer import RagIndexer
from app.domain.ai.ai_provider import AIProvider
from app.domain.entities.user import UserEntity
from app.domain.repositories.achievement_repository import (
    IAchievementRepository,
)
from app.domain.repositories.answer_repository import IAnswerRepository
from app.domain.repositories.chunk_repository import IChunkRepository
from app.domain.repositories.flashcard_repository import IFlashcardRepository
from app.domain.repositories.material_repository import IMaterialRepository
from app.domain.repositories.message_repository import IMessageRepository
from app.domain.repositories.quiz_repository import IQuizRepository
from app.domain.repositories.stats_repository import IStatsRepository
from app.domain.repositories.subject_repository import ISubjectRepository
from app.domain.repositories.theme_context import IThemeContextProvider
from app.domain.repositories.user_repository import IUserRepository
from app.domain.services.file_storage import IFileStorage
from app.domain.services.indexer import IMaterialIndexer
from app.domain.services.text_extraction import ITextExtractionService
from app.domain.services.vector_store import IVectorStore
from app.infrastructure.ai.factory import get_ai_provider
from app.infrastructure.db.repositories.achievement_repository import (
    SqlAchievementRepository,
)
from app.infrastructure.db.repositories.answer_repository import (
    SqlAnswerRepository,
)
from app.infrastructure.db.repositories.chunk_repository import (
    SqlChunkRepository,
)
from app.infrastructure.db.repositories.flashcard_repository import (
    SqlFlashcardRepository,
)
from app.infrastructure.db.repositories.material_repository import (
    SqlMaterialRepository,
)
from app.infrastructure.db.repositories.message_repository import (
    SqlMessageRepository,
)
from app.infrastructure.db.repositories.quiz_repository import (
    SqlQuizRepository,
)
from app.infrastructure.db.repositories.stats_repository import (
    SqlStatsRepository,
)
from app.infrastructure.db.repositories.subject_repository import (
    SqlSubjectRepository,
)
from app.infrastructure.db.repositories.theme_context import (
    SqlThemeContextProvider,
)
from app.infrastructure.db.repositories.user_repository import SqlUserRepository
from app.infrastructure.extraction.service import ExtractionService
from app.infrastructure.rag.chroma_store import ChromaVectorStore
from app.infrastructure.rag.rag_context import RagThemeContextProvider
from app.infrastructure.storage.local_storage import LocalFileStorage

oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl=f"{settings.api_v1_prefix}/auth/login", auto_error=False
)

DbSession = Annotated[Session, Depends(get_db)]


def get_user_repository(db: DbSession) -> IUserRepository:
    return SqlUserRepository(db)


UserRepo = Annotated[IUserRepository, Depends(get_user_repository)]
AIProviderDep = Annotated[AIProvider, Depends(get_ai_provider)]


def get_subject_repository(db: DbSession) -> ISubjectRepository:
    return SqlSubjectRepository(db)


def get_vector_store() -> IVectorStore:
    return ChromaVectorStore()


VectorStoreDep = Annotated[IVectorStore, Depends(get_vector_store)]


def get_theme_context_provider(
    db: DbSession, ai: AIProviderDep, vectors: VectorStoreDep
) -> IThemeContextProvider:
    # RAG com fallback para texto completo (resiliente a Ollama/Chroma fora do ar)
    return RagThemeContextProvider(ai, vectors, SqlThemeContextProvider(db))


SubjectRepo = Annotated[ISubjectRepository, Depends(get_subject_repository)]
ThemeContextDep = Annotated[
    IThemeContextProvider, Depends(get_theme_context_provider)
]


def get_chunk_repository(db: DbSession) -> IChunkRepository:
    return SqlChunkRepository(db)


def get_indexer(
    db: DbSession, ai: AIProviderDep, vectors: VectorStoreDep
) -> IMaterialIndexer:
    return RagIndexer(ai, SqlChunkRepository(db), vectors)


IndexerDep = Annotated[IMaterialIndexer, Depends(get_indexer)]


def get_flashcard_repository(db: DbSession) -> IFlashcardRepository:
    return SqlFlashcardRepository(db)


def get_quiz_repository(db: DbSession) -> IQuizRepository:
    return SqlQuizRepository(db)


FlashcardRepo = Annotated[
    IFlashcardRepository, Depends(get_flashcard_repository)
]
QuizRepo = Annotated[IQuizRepository, Depends(get_quiz_repository)]


def get_message_repository(db: DbSession) -> IMessageRepository:
    return SqlMessageRepository(db)


MessageRepo = Annotated[IMessageRepository, Depends(get_message_repository)]


def get_answer_repository(db: DbSession) -> IAnswerRepository:
    return SqlAnswerRepository(db)


AnswerRepo = Annotated[IAnswerRepository, Depends(get_answer_repository)]


def get_stats_repository(db: DbSession) -> IStatsRepository:
    return SqlStatsRepository(db)


def get_achievement_repository(db: DbSession) -> IAchievementRepository:
    return SqlAchievementRepository(db)


StatsRepo = Annotated[IStatsRepository, Depends(get_stats_repository)]
AchievementRepo = Annotated[
    IAchievementRepository, Depends(get_achievement_repository)
]


def get_material_repository(db: DbSession) -> IMaterialRepository:
    return SqlMaterialRepository(db)


def get_file_storage() -> IFileStorage:
    return LocalFileStorage()


def get_extraction_service() -> ITextExtractionService:
    return ExtractionService()


MaterialRepo = Annotated[IMaterialRepository, Depends(get_material_repository)]
FileStorageDep = Annotated[IFileStorage, Depends(get_file_storage)]
ExtractionDep = Annotated[
    ITextExtractionService, Depends(get_extraction_service)
]


def get_current_user(
    users: UserRepo,
    token: Annotated[str | None, Depends(oauth2_scheme)],
) -> UserEntity:
    if not token:
        raise UnauthorizedError("Token de autenticação ausente.")
    subject = decode_access_token(token)
    if subject is None:
        raise UnauthorizedError("Token inválido ou expirado.")
    user = users.get_by_id(int(subject))
    if user is None:
        raise UnauthorizedError("Usuário não encontrado.")
    return user


CurrentUser = Annotated[UserEntity, Depends(get_current_user)]
