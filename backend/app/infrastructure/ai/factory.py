"""Factory que resolve o AIProvider ativo (local/ollama ou nuvem/gemini).

O provedor ativo é dinâmico (app.core.runtime), então dá pra trocar Local/Nuvem
em tempo de execução, sem reiniciar. Toda chamada é registrada (ai_logs).
"""
from app.core.runtime import get_active_provider
from app.domain.ai.ai_provider import AIProvider
from app.infrastructure.ai.gemini_provider import GeminiProvider
from app.infrastructure.ai.logging_provider import LoggingAIProvider
from app.infrastructure.ai.ollama_provider import OllamaProvider

_PROVIDERS: dict[str, type[AIProvider]] = {
    "ollama": OllamaProvider,   # IA local (Qwen3)
    "gemini": GeminiProvider,   # IA nuvem (Google Gemini)
}

# Nomes amigáveis para a UI.
PROVIDER_LABELS = {"ollama": "Local (Qwen3)", "gemini": "Nuvem (Gemini)"}


def get_ai_provider() -> AIProvider:
    """Retorna o provedor de IA ativo, com registro de uso (ai_logs)."""
    name = get_active_provider()
    provider_cls = _PROVIDERS.get(name)
    if provider_cls is None:
        raise ValueError(
            f"Provedor de IA não suportado: '{name}'. "
            f"Disponíveis: {', '.join(_PROVIDERS)}"
        )
    return LoggingAIProvider(provider_cls())
