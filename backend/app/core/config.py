"""Configuração central da aplicação, carregada de variáveis de ambiente."""
from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", extra="ignore"
    )

    # App
    app_name: str = "GowienHelper"
    app_env: str = "development"
    debug: bool = True
    api_v1_prefix: str = "/api/v1"

    # Security
    secret_key: str = "change-me"
    access_token_expire_minutes: int = 10080
    algorithm: str = "HS256"

    # Database
    database_url: str = "postgresql+psycopg2://gowien:gowien@localhost:5432/gowien"

    # AI Provider
    ai_provider: str = "ollama"
    ollama_base_url: str = "http://localhost:11434"
    ollama_model: str = "qwen3:8b"
    ollama_embed_model: str = "nomic-embed-text"
    openai_api_key: str = ""
    anthropic_api_key: str = ""
    gemini_api_key: str = ""

    # Vector store
    chroma_host: str = "localhost"
    chroma_port: int = 8001

    # Storage
    storage_dir: str = "./storage"


@lru_cache
def get_settings() -> Settings:
    """Retorna a instância única (cache) das configurações."""
    return Settings()


settings = get_settings()
