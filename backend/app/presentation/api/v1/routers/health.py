"""Health check da API."""
import httpx
from fastapi import APIRouter

from app.core.config import settings

router = APIRouter(tags=["Health"])


@router.get("/health", summary="Verifica se a API está no ar")
def health() -> dict[str, str]:
    return {"status": "ok"}


@router.get("/health/ai", summary="Status do provedor de IA (Ollama/Qwen3)")
async def ai_health() -> dict:
    """Reporta provedor, modelo e se o Ollama está acessível com o modelo baixado."""
    info: dict = {
        "provider": settings.ai_provider,
        "model": settings.ollama_model,
        "embed_model": settings.ollama_embed_model,
        "base_url": settings.ollama_base_url,
        "available": False,
        "model_ready": False,
    }
    if settings.ai_provider != "ollama":
        return info
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            resp = await client.get(f"{settings.ollama_base_url}/api/tags")
            resp.raise_for_status()
            names = [m.get("name", "") for m in resp.json().get("models", [])]
        info["available"] = True
        base = settings.ollama_model.split(":")[0]
        info["model_ready"] = any(
            n == settings.ollama_model or n.split(":")[0] == base for n in names
        )
    except Exception:  # noqa: BLE001 - status é best-effort
        pass
    return info
