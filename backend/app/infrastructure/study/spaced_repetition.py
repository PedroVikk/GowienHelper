"""Algoritmo de repetição espaçada SM-2 (puro, sem I/O).

Qualidade da resposta (0–5): 0–2 = errou (reinicia), 3 = difícil, 4 = bom,
5 = fácil. Retorna o novo estado de agendamento do card.
"""
from dataclasses import dataclass

MIN_EASE = 1.3


@dataclass(slots=True)
class SrState:
    ease_factor: float
    interval_days: int
    repetitions: int


def review(state: SrState, quality: int) -> SrState:
    if not 0 <= quality <= 5:
        raise ValueError("quality deve estar entre 0 e 5")

    if quality < 3:
        repetitions = 0
        interval = 1
    else:
        if state.repetitions == 0:
            interval = 1
        elif state.repetitions == 1:
            interval = 6
        else:
            interval = round(state.interval_days * state.ease_factor)
        repetitions = state.repetitions + 1

    ease = state.ease_factor + (
        0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)
    )
    ease = max(MIN_EASE, ease)

    return SrState(
        ease_factor=round(ease, 3),
        interval_days=interval,
        repetitions=repetitions,
    )
