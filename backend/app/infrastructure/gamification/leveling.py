"""Regras puras de gamificação: XP, nível e streak (sem I/O)."""
from datetime import date, timedelta

XP_PER_LEVEL = 100
XP_CORRECT = 10
XP_WRONG = 2


def xp_for_answer(is_correct: bool) -> int:
    """XP ganho ao responder (acerto vale mais; errar ainda incentiva tentar)."""
    return XP_CORRECT if is_correct else XP_WRONG


def level_for_xp(xp: int) -> int:
    """Nível a partir do XP acumulado (começa em 1)."""
    return max(1, xp // XP_PER_LEVEL + 1)


def xp_into_level(xp: int) -> tuple[int, int]:
    """Retorna (xp dentro do nível atual, xp necessário para o próximo)."""
    return xp % XP_PER_LEVEL, XP_PER_LEVEL


def streak_from_dates(dates: set[date], today: date) -> int:
    """Dias consecutivos de estudo terminando hoje (ou ontem, se hoje vazio)."""
    if today in dates:
        cursor = today
    elif (today - timedelta(days=1)) in dates:
        cursor = today - timedelta(days=1)
    else:
        return 0

    count = 0
    while cursor in dates:
        count += 1
        cursor -= timedelta(days=1)
    return count
