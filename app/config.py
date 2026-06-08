"""Configuration de l'application, chargée depuis les variables d'environnement."""

from __future__ import annotations

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "FastAPI Docker Optimized"
    environment: str = "development"
    port: int = 8000


settings = Settings()