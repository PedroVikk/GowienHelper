"""Casos de uso de gamificação: XP por resposta e conquistas."""
from collections.abc import Callable
from dataclasses import dataclass
from datetime import datetime, timezone

from app.domain.entities.user import UserEntity
from app.domain.repositories.achievement_repository import (
    IAchievementRepository,
)
from app.domain.repositories.stats_repository import IStatsRepository
from app.domain.repositories.user_repository import IUserRepository
from app.infrastructure.gamification.leveling import (
    streak_from_dates,
    xp_for_answer,
)


@dataclass(slots=True)
class Snapshot:
    answered: int
    correct: int
    accuracy: float
    streak: int


@dataclass(slots=True)
class AchievementDef:
    code: str
    title: str
    description: str
    predicate: Callable[[Snapshot], bool]


@dataclass(slots=True)
class AchievementStatus:
    code: str
    title: str
    description: str
    unlocked: bool


# Catálogo de conquistas (fácil de estender).
ACHIEVEMENTS: list[AchievementDef] = [
    AchievementDef("first_answer", "Primeiros passos", "Responda 1 questão",
                   lambda s: s.answered >= 1),
    AchievementDef("ten_correct", "Afiado", "Acerte 10 questões",
                   lambda s: s.correct >= 10),
    AchievementDef("accuracy_ace", "Precisão", "80% de acerto em 20+ questões",
                   lambda s: s.answered >= 20 and s.accuracy >= 0.8),
    AchievementDef("streak_3", "Constância", "3 dias seguidos estudando",
                   lambda s: s.streak >= 3),
    AchievementDef("streak_7", "Disciplinado", "7 dias seguidos estudando",
                   lambda s: s.streak >= 7),
    AchievementDef("centurion", "Centurião", "Responda 100 questões",
                   lambda s: s.answered >= 100),
]


class AwardXpUseCase:
    def __init__(self, users: IUserRepository) -> None:
        self._users = users

    def execute(self, user_id: int, is_correct: bool) -> UserEntity:
        return self._users.add_xp(user_id, xp_for_answer(is_correct))


class CheckAchievementsUseCase:
    def __init__(
        self, stats: IStatsRepository, achievements: IAchievementRepository
    ) -> None:
        self._stats = stats
        self._achievements = achievements

    def execute(self, user_id: int) -> list[AchievementStatus]:
        totals = self._stats.totals(user_id)
        accuracy = totals.correct / totals.answered if totals.answered else 0.0
        streak = streak_from_dates(
            self._stats.activity_dates(user_id),
            datetime.now(timezone.utc).date(),
        )
        snapshot = Snapshot(totals.answered, totals.correct, accuracy, streak)

        already = self._achievements.unlocked_codes(user_id)
        result: list[AchievementStatus] = []
        for a in ACHIEVEMENTS:
            unlocked = a.code in already
            if not unlocked and a.predicate(snapshot):
                self._achievements.unlock(user_id, a.code, a.title, a.description)
                unlocked = True
            result.append(
                AchievementStatus(a.code, a.title, a.description, unlocked)
            )
        return result
