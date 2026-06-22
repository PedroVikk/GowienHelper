"""Provedor de IA na nuvem via API do Google Gemini (tier gratuito)."""
import httpx

from app.core.config import settings
from app.core.exceptions import ValidationError
from app.infrastructure.ai.base_llm_provider import BaseLLMProvider

_BASE = "https://generativelanguage.googleapis.com/v1beta"


class GeminiProvider(BaseLLMProvider):
    def __init__(
        self,
        api_key: str | None = None,
        model: str | None = None,
        embed_model: str | None = None,
        timeout: float = 120.0,
    ) -> None:
        self._key = api_key or settings.gemini_api_key
        self._model = model or settings.gemini_model
        self._embed_model = embed_model or settings.gemini_embed_model
        self._timeout = timeout

    def _ensure_key(self) -> None:
        if not self._key:
            raise ValidationError(
                "GEMINI_API_KEY não configurada. Adicione a chave no .env do "
                "backend para usar a IA na nuvem."
            )

    async def _generate(self, prompt: str, temperature: float = 0.3) -> str:
        self._ensure_key()
        url = f"{_BASE}/models/{self._model}:generateContent?key={self._key}"
        payload = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {"temperature": temperature},
        }
        async with httpx.AsyncClient(timeout=self._timeout) as client:
            resp = await client.post(url, json=payload)
            if resp.status_code == 429:
                raise ValidationError(
                    "O limite gratuito da IA na nuvem acabou por hoje. "
                    "Tente de novo amanha ou troque para a IA local em Ajustes."
                )
            resp.raise_for_status()
            data = resp.json()
        candidates = data.get("candidates") or []
        if not candidates:
            return ""
        parts = candidates[0].get("content", {}).get("parts", [])
        return "".join(p.get("text", "") for p in parts).strip()

    async def embed(self, texts: list[str]) -> list[list[float]]:
        self._ensure_key()
        url = f"{_BASE}/models/{self._embed_model}:embedContent?key={self._key}"
        out: list[list[float]] = []
        async with httpx.AsyncClient(timeout=self._timeout) as client:
            for text in texts:
                resp = await client.post(url, json={
                    "model": f"models/{self._embed_model}",
                    "content": {"parts": [{"text": text}]},
                })
                resp.raise_for_status()
                out.append(resp.json().get("embedding", {}).get("values", []))
        return out
