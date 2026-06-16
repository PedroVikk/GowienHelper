"""DTOs de estatísticas e gamificação."""
from pydantic import BaseModel


class OverviewResponse(BaseModel):
    questions_answered: int
    correct_answers: int
    accuracy: float
    time_studied_seconds: int
    xp: int
    level: int
    xp_in_level: int
    xp_to_next_level: int
    streak: int


class SubjectStatResponse(BaseModel):
    subject_id: int
    name: str
    answered: int
    correct: int
    accuracy: float


class DailyStatResponse(BaseModel):
    day: str
    answered: int
    correct: int


class AchievementResponse(BaseModel):
    code: str
    title: str
    description: str
    unlocked: bool
