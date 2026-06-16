"""Factory que resolve o AIProvider configurado.

Ponto único de troca de provedor. Para adicionar OpenAI/Anthropic/Gemini,
basta criar a implementação de AIProvider e registrá-la aqui.
"""
from app.core.config import settings
from app.domain.ai.ai_provider import AIProvider
from app.infrastructure.ai.ollama_provider import OllamaProvider

_PROVIDERS: dict[str, type[AIProvider]] = {
    "ollama": OllamaProvider,
    # "openai": OpenAIProvider,
    # "anthropic": AnthropicProvider,
    # "gemini": GeminiProvider,
}


def get_ai_provider() -> AIProvider:
    """Retorna a instância do provedor de IA definido em settings.ai_provider."""
    provider_cls = _PROVIDERS.get(settings.ai_provider)
    if provider_cls is None:
        raise ValueError(
            f"Provedor de IA não suportado: '{settings.ai_provider}'. "
            f"Disponíveis: {', '.join(_PROVIDERS)}"
        )
    return provider_cls()
