"""Extração resiliente de JSON da saída de LLMs."""
import json
import re
from typing import Any

_THINK_RE = re.compile(r"<think>.*?</think>", re.DOTALL)
_FENCE_RE = re.compile(r"```(?:json)?\s*(.*?)\s*```", re.DOTALL)


def strip_think(text: str) -> str:
    """Remove blocos <think>...</think> (Qwen3 e similares)."""
    return _THINK_RE.sub("", text).strip()


def extract_json(text: str) -> Any:
    """Extrai o primeiro objeto/array JSON válido de um texto livre.

    Levanta ValueError se nada parseável for encontrado.
    """
    cleaned = strip_think(text)

    fence = _FENCE_RE.search(cleaned)
    if fence:
        cleaned = fence.group(1)

    try:
        return json.loads(cleaned)
    except json.JSONDecodeError:
        pass

    # Fallback: recorta do primeiro { ou [ até o fechamento correspondente.
    for open_ch, close_ch in (("{", "}"), ("[", "]")):
        start = cleaned.find(open_ch)
        end = cleaned.rfind(close_ch)
        if start != -1 and end > start:
            try:
                return json.loads(cleaned[start : end + 1])
            except json.JSONDecodeError:
                continue

    raise ValueError("Nenhum JSON válido encontrado na resposta da IA")
