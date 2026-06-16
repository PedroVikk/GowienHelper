"""Porta de estatísticas (agregações de desempenho do usuário)."""
from abc import ABC, abstractmethod
from dataclasses import dataclass
from datetime import date


@dataclass(slots=True)
class Totals:
    answered: int
    correct: int
    time_seconds: int


@dataclass(slots=True)
class SubjectStat:
    subject_id: int
    name: str
    answered: int
    correct: int
    accuracy: float


@dataclass(slots=True)
class DailyStat:
    day: str  # YYYY-MM-DD
    answered: int
    correct: int


class IStatsRepository(ABC):
    @abstractmethod
    def totals(self, user_id: int) -> Totals: ...

    @abstractmethod
    def by_subject(self, user_id: int) -> list[SubjectStat]:
        """Por disciplina, ordenado da MENOR acurácia (mais difícil) à maior."""

    @abstractmethod
    def evolution(self, user_id: int, days: int) -> list[DailyStat]: ...

    @abstractmethod
    def activity_dates(self, user_id: int) -> set[date]:
        """Dias (date) em que o usuário respondeu algo — base para o streak."""
