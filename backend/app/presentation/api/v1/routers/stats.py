"""Rotas de estatísticas e gamificação."""
from dataclasses import asdict
from typing import Annotated

from app.application.dtos.stats import (
    AchievementResponse,
    DailyStatResponse,
    OverviewResponse,
    SubjectStatResponse,
)
from app.application.use_cases.gamification import CheckAchievementsUseCase
from app.application.use_cases.stats import (
    GetEvolutionUseCase,
    GetOverviewUseCase,
    GetSubjectStatsUseCase,
)
from app.presentation.api.deps import (
    AchievementRepo,
    CurrentUser,
    StatsRepo,
)
from fastapi import APIRouter, Query

router = APIRouter(prefix="/stats", tags=["Estatísticas"])


@router.get(
    "/overview", response_model=OverviewResponse, summary="Resumo de desempenho + XP"
)
def overview(user: CurrentUser, stats: StatsRepo) -> OverviewResponse:
    o = GetOverviewUseCase(stats).execute(user)
    return OverviewResponse(**asdict(o))


@router.get(
    "/by-subject",
    response_model=list[SubjectStatResponse],
    summary="Desempenho por disciplina (mais difíceis primeiro)",
)
def by_subject(
    user: CurrentUser, stats: StatsRepo
) -> list[SubjectStatResponse]:
    items = GetSubjectStatsUseCase(stats).execute(user.id)
    return [SubjectStatResponse(**asdict(s)) for s in items]


@router.get(
    "/evolution",
    response_model=list[DailyStatResponse],
    summary="Evolução diária (últimos N dias)",
)
def evolution(
    user: CurrentUser,
    stats: StatsRepo,
    days: Annotated[int, Query(ge=1, le=365)] = 30,
) -> list[DailyStatResponse]:
    items = GetEvolutionUseCase(stats).execute(user.id, days)
    return [DailyStatResponse(**asdict(d)) for d in items]


@router.get(
    "/achievements",
    response_model=list[AchievementResponse],
    summary="Conquistas (desbloqueia as recém-conquistadas)",
)
def achievements(
    user: CurrentUser, stats: StatsRepo, achievements_repo: AchievementRepo
) -> list[AchievementResponse]:
    items = CheckAchievementsUseCase(stats, achievements_repo).execute(user.id)
    return [AchievementResponse(**asdict(a)) for a in items]
