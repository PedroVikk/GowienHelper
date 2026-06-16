"""Testes do algoritmo SM-2 (repetição espaçada)."""
import pytest

from app.infrastructure.study.spaced_repetition import SrState, review


def test_first_good_review():
    out = review(SrState(2.5, 0, 0), quality=5)
    assert out.repetitions == 1
    assert out.interval_days == 1
    assert out.ease_factor > 2.5  # acerto fácil aumenta a facilidade


def test_second_good_review_interval_six():
    out = review(SrState(2.5, 1, 1), quality=4)
    assert out.repetitions == 2
    assert out.interval_days == 6


def test_third_review_multiplies_interval():
    out = review(SrState(2.5, 6, 2), quality=4)
    assert out.repetitions == 3
    assert out.interval_days == round(6 * 2.5)


def test_fail_resets():
    out = review(SrState(2.8, 30, 5), quality=1)
    assert out.repetitions == 0
    assert out.interval_days == 1


def test_ease_has_floor():
    state = SrState(1.3, 10, 3)
    out = review(state, quality=0)
    assert out.ease_factor >= 1.3


def test_invalid_quality():
    with pytest.raises(ValueError):
        review(SrState(2.5, 0, 0), quality=9)
