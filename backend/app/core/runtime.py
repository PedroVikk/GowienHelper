"""Estado de runtime que pode ser alterado em tempo de execução (sem reiniciar).

Hoje guarda só o provedor de IA ativo (local/ollama ou nuvem/gemini),
persistido em backend/runtime.json para sobreviver a reinícios.
"""
import json
from pathlib import Path

from app.core.config import settings

_FILE = Path(__file__).resolve().parents[2] / "runtime.json"


def get_active_provider() -> str:
    try:
        data = json.loads(_FILE.read_text(encoding="utf-8"))
        provider = data.get("ai_provider")
        if provider:
            return provider
    except Exception:  # noqa: BLE001
        pass
    return settings.ai_provider


def set_active_provider(name: str) -> None:
    _FILE.write_text(json.dumps({"ai_provider": name}), encoding="utf-8")
