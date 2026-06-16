"""Testes das regras puras de gamificação (XP, nível, streak)."""
from datetime import date, timedelta

from app.infrastructure.gamification.leveling import (
    level_for_xp,
    streak_from_dates,
    xp_for_answer,
    xp_into_level,
)


def test_xp_for_answer():
    assert xp_for_answer(True) == 10
    assert xp_for_answer(False) == 2


def test_level_for_xp():
    assert level_for_xp(0) == 1
    assert level_for_xp(99) == 1
    assert level_for_xp(100) == 2
    assert level_for_xp(250) == 3


def test_xp_into_level():
    assert xp_into_level(250) == (50, 100)


def test_streak_consecutive_including_today():
    today = date(2026, 6, 16)
    days = {today, today - timedelta(days=1), today - timedelta(days=2)}
    assert streak_from_dates(days, today) == 3


def test_streak_breaks_on_gap():
    today = date(2026, 6, 16)
    days = {today, today - timedelta(days=2)}  # falta ontem
    assert streak_from_dates(days, today) == 1


def test_streak_counts_from_yesterday_if_today_empty():
    today = date(2026, 6, 16)
    days = {today - timedelta(days=1), today - timedelta(days=2)}
    assert streak_from_dates(days, today) == 2


def test_streak_zero_when_stale():
    today = date(2026, 6, 16)
    days = {today - timedelta(days=5)}
    assert streak_from_dates(days, today) == 0
