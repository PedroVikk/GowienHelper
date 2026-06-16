"""Saneamento puro das questões geradas (sem I/O, testável offline).

Primeira linha de defesa do anti-drift: descarta questões malformadas,
duplicadas ou sem resposta, e limita à quantidade pedida. A trava de TEMA em
si é feita pelo prompt; aqui garantimos integridade do resultado.
"""
from app.domain.ai.models import GeneratedQuestion, QuestionType


def _normalize(text: str) -> str:
    return " ".join(text.lower().split())


def sanitize_questions(
    questions: list[GeneratedQuestion], count: int
) -> list[GeneratedQuestion]:
    seen: set[str] = set()
    result: list[GeneratedQuestion] = []

    for q in questions:
        prompt = q.prompt.strip()
        if not prompt or not q.correct_answer.strip():
            continue  # malformada

        # múltipla escolha precisa de opções coerentes
        if q.type == QuestionType.MULTIPLE_CHOICE and len(q.options) < 2:
            continue

        key = _normalize(prompt)
        if key in seen:
            continue  # duplicada
        seen.add(key)

        result.append(q)
        if len(result) >= count:
            break

    return result
