"""Casos de uso de estatísticas de desempenho."""
from dataclasses import dataclass
from datetime import datetime, timezone

from app.domain.entities.user import UserEntity
from app.domain.repositories.stats_repository import (
    DailyStat,
    IStatsRepository,
    SubjectStat,
)
from app.infrastructure.gamification.leveling import (
    streak_from_dates,
    xp_into_level,
)


@dataclass(slots=True)
class Overview:
    questions_answered: int
    correct_answers: int
    accuracy: float
    time_studied_seconds: int
    xp: int
    level: int
    xp_in_level: int
    xp_to_next_level: int
    streak: int


class GetOverviewUseCase:
    def __init__(self, stats: IStatsRepository) -> None:
        self._stats = stats

    def execute(self, user: UserEntity) -> Overview:
        totals = self._stats.totals(user.id)
        accuracy = (
            round(totals.correct / totals.answered, 3) if totals.answered else 0.0
        )
        streak = streak_from_dates(
            self._stats.activity_dates(user.id),
            datetime.now(timezone.utc).date(),
        )
        in_level, to_next = xp_into_level(user.xp)
        return Overview(
            questions_answered=totals.answered,
            correct_answers=totals.correct,
            accuracy=accuracy,
            time_studied_seconds=totals.time_seconds,
            xp=user.xp,
            level=user.level,
            xp_in_level=in_level,
            xp_to_next_level=to_next,
            streak=streak,
        )


class GetSubjectStatsUseCase:
    def __init__(self, stats: IStatsRepository) -> None:
        self._stats = stats

    def execute(self, user_id: int) -> list[SubjectStat]:
        return self._stats.by_subject(user_id)


class GetEvolutionUseCase:
    def __init__(self, stats: IStatsRepository) -> None:
        self._stats = stats

    def execute(self, user_id: int, days: int) -> list[DailyStat]:
        return self._stats.evolution(user_id, days)
