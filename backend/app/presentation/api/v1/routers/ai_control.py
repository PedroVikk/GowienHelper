"""Controle da IA: status, troca Local/Nuvem e aviso de limite de uso."""
import httpx
from fastapi import APIRouter
from pydantic import BaseModel
from sqlalchemy import func, select

from app.core.config import settings
from app.core.database import SessionLocal
from app.core.runtime import get_active_provider, set_active_provider
from app.infrastructure.ai.factory import PROVIDER_LABELS, _PROVIDERS
from app.infrastructure.db.models.ai_log import AiLog

router = APIRouter(prefix="/ai", tags=["IA"])


class ProviderRequest(BaseModel):
    provider: str  # "ollama" | "gemini"


async def _ollama_online() -> bool:
    try:
        async with httpx.AsyncClient(timeout=4.0) as c:
            await c.get(f"{settings.ollama_base_url}/api/tags")
        return True
    except Exception:  # noqa: BLE001
        return False


def _gemini_usage_today() -> int:
    """Conta gerações Gemini de hoje (exclui embeddings, que têm cota própria)."""
    with SessionLocal() as db:
        return db.scalar(
            select(func.count()).select_from(AiLog).where(
                AiLog.model.like("gemini%"),
                AiLog.operation != "embed",
                func.date(AiLog.created_at) == func.date(func.now()),
            )
        ) or 0


def _gemini_usage_block() -> dict:
    used = _gemini_usage_today()
    limit = settings.gemini_daily_limit
    remaining = max(limit - used, 0)
    exhausted = remaining <= 0
    warn = remaining <= max(int(limit * 0.15), 1)  # alerta nos últimos ~15%
    message = None
    if exhausted:
        message = ("A IA na nuvem atingiu o limite grátis de hoje 😕. "
                   "Volte amanhã ou use a IA local em Ajustes.")
    elif warn:
        message = (f"Você já usou {used} de {limit} gerações grátis hoje. "
                   f"Restam cerca de {remaining} — depois disso, troque para a "
                   "IA local ou aguarde amanhã. 🙂")
    return {
        "used_today": used, "limit": limit, "remaining": remaining,
        "warn": warn, "exhausted": exhausted, "message": message,
    }


@router.get("/status", summary="Status da IA: provedor ativo, modelos e uso")
async def ai_status() -> dict:
    active = get_active_provider()
    ollama_ok = await _ollama_online()
    gemini_ok = bool(settings.gemini_api_key)

    providers = [
        {"id": "ollama", "label": PROVIDER_LABELS["ollama"],
         "available": ollama_ok, "model": settings.ollama_model},
        {"id": "gemini", "label": PROVIDER_LABELS["gemini"],
         "available": gemini_ok, "model": settings.gemini_model},
    ]
    online = ollama_ok if active == "ollama" else gemini_ok
    model = settings.ollama_model if active == "ollama" else settings.gemini_model

    return {
        "active": active,
        "active_label": PROVIDER_LABELS.get(active, active),
        "model": model,
        "online": online,
        "providers": providers,
        # aviso de cota só faz sentido na nuvem
        "usage": _gemini_usage_block() if active == "gemini" else None,
    }


@router.post("/provider", summary="Troca a IA entre Local (Qwen3) e Nuvem (Gemini)")
def set_provider(payload: ProviderRequest) -> dict:
    name = payload.provider.strip().lower()
    if name not in _PROVIDERS:
        return {"ok": False, "error": f"Provedor inválido: {name}"}
    if name == "gemini" and not settings.gemini_api_key:
        return {
            "ok": False,
            "error": "Configure a GEMINI_API_KEY no backend para usar a nuvem.",
        }
    set_active_provider(name)
    return {"ok": True, "active": name, "label": PROVIDER_LABELS[name]}
