# syntax=docker/dockerfile:1.9
# ============================================================================
#  Étape 1 — BUILD : on installe les dépendances avec uv dans une image
#  de travail. uv et tout l'outillage de build resteront ici, hors de
#  l'image finale.
# ============================================================================
FROM python:3.12-slim AS builder

# Binaire uv copié directement depuis l'image officielle (pas de pip install).
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Réglages uv :
# - compile bytecode = démarrage plus rapide du conteneur
# - copy = ne pas dépendre de hardlinks vers le cache (qui vit hors image)
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

WORKDIR /app

# --- Cache de layers -------------------------------------------------------
# On copie D'ABORD les seuls fichiers de dépendances. Tant qu'ils ne bougent
# pas, Docker réutilise la couche d'installation depuis le cache, même si le
# code applicatif change juste en dessous.
COPY pyproject.toml uv.lock* ./

# --- Cache mount -----------------------------------------------------------
# Le cache des téléchargements uv reste HORS de l'image finale (il n'alourdit
# rien) mais persiste entre les builds : uv réutilise les packages déjà
# récupérés au lieu de tout retélécharger.
#
# --no-install-project : on installe UNIQUEMENT les dépendances ici. Le code
# applicatif n'a pas besoin de passer par le builder (ce sont des fichiers
# statiques) : on le copiera directement dans l'image finale.
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project --no-dev


# ============================================================================
#  Étape 2 — RUNTIME : image finale, ne contient QUE le strict nécessaire à
#  l'exécution. Ni uv, ni outillage de build.
# ============================================================================
FROM python:3.12-slim AS runtime

# --- Bonus sécurité : utilisateur non-root ---------------------------------
# On crée un user dédié et on lui donne la propriété de l'app : le conteneur
# ne tourne pas en root.
RUN groupadd --system app && useradd --system --gid app --no-create-home appuser

WORKDIR /app

# Le venv (les dépendances) vient du builder. Le code, lui, est copié
# directement depuis le contexte : pas besoin de le faire transiter par le
# builder. uv et le cache restent derrière.
COPY --from=builder --chown=appuser:app /app/.venv /app/.venv
COPY --chown=appuser:app ./app /app/app

# Le venv en tête de PATH : pas besoin d'activer quoi que ce soit.
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

USER appuser

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
