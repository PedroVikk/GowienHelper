"""Provedor de IA local via API HTTP do Ollama (ex.: qwen3:8b)."""
import httpx

from app.core.config import settings
from app.infrastructure.ai.base_llm_provider import BaseLLMProvider
from app.infrastructure.ai.json_utils import strip_think


class OllamaProvider(BaseLLMProvider):
    def __init__(
        self,
        base_url: str | None = None,
        model: str | None = None,
        embed_model: str | None = None,
        timeout: float = 300.0,
    ) -> None:
        self._base_url = (base_url or settings.ollama_base_url).rstrip("/")
        self._model = model or settings.ollama_model
        self._embed_model = embed_model or settings.ollama_embed_model
        self._timeout = timeout

    async def _generate(self, prompt: str, temperature: float = 0.3) -> str:
        payload = {
            "model": self._model,
            "prompt": prompt,
            "stream": False,
            "think": False,
            "options": {"temperature": temperature},
        }
        async with httpx.AsyncClient(timeout=self._timeout) as client:
            resp = await client.post(f"{self._base_url}/api/generate", json=payload)
            resp.raise_for_status()
            data = resp.json()
        return strip_think(data.get("response", ""))

    async def embed(self, texts: list[str]) -> list[list[float]]:
        embeddings: list[list[float]] = []
        async with httpx.AsyncClient(timeout=self._timeout) as client:
            for text in texts:
                resp = await client.post(
                    f"{self._base_url}/api/embeddings",
                    json={"model": self._embed_model, "prompt": text},
                )
                resp.raise_for_status()
                embeddings.append(resp.json().get("embedding", []))
        return embeddings
