# 🐳 FastAPI Docker Optimized

Un repo minimal qui montre comment **builder une image Docker rapide et légère**
pour une API REST Python — en appliquant les bonnes pratiques une par une.

> API REST en FastAPI, gérée avec `uv`, conteneurisée avec un `Dockerfile`
> multi-stage sur base `slim`, exécutée en utilisateur non-root.

---

## 🚀 Démarrer

### En local (sans Docker)

```bash
# uv installe tout depuis le pyproject.toml
uv sync

# Lancer l'API
uv run uvicorn app.main:app --reload
```

### Avec Docker

```bash
cp .env.example .env
docker compose up --build
```

L'API est dispo sur http://localhost:8000
Documentation interactive (Swagger) : http://localhost:8000/docs

### Endpoints

| Méthode | Route             | Description              |
|---------|-------------------|--------------------------|
| GET     | `/`               | Message de bienvenue     |
| GET     | `/health`         | Healthcheck              |
| GET     | `/items`          | Lister les items         |
| GET     | `/items/{id}`     | Récupérer un item        |
| POST    | `/items`          | Créer un item            |
| DELETE  | `/items/{id}`     | Supprimer un item        |

---

## 🎯 Les bonnes pratiques, fichier par fichier

### ⚡ Temps de construction

**1. `uv` plutôt que `pip`** — gestionnaire de packages écrit en Rust, bien
plus rapide. Le binaire est copié directement depuis l'image officielle dans
le `Dockerfile`, aucun `pip install` n'est nécessaire.

**2. Le cache, sur deux niveaux** (voir `Dockerfile`) :
- **Cache de layers** : on copie d'abord `pyproject.toml` / `uv.lock`, on
  installe, puis on copie le code *ensuite*. Tant que les dépendances ne
  bougent pas, l'installation reste en cache même quand le code change.
- **Cache mount** : `RUN --mount=type=cache,target=/root/.cache/uv uv sync`
  garde les téléchargements `uv` hors de l'image, mais persistants entre builds.

> ⚠️ En CI, le runner est éphémère : il faut configurer la persistance du
> cache côté runner, sinon chaque pipeline repart de zéro.

### 🪶 Légèreté de l'image

**3. `.dockerignore` soigné** — tests, `.env`, doc et caches ne sont jamais
copiés dans l'image.

**4. Multi-stage** — l'étape `builder` installe les dépendances avec `uv` ;
l'étape `runtime` ne récupère que le venv et le code. `uv` et l'outillage de
build restent derrière.

**5. Base `python:3.12-slim`** — le minimum vital pour faire tourner Python.

### 🔒 Bonus sécurité

Le conteneur ne tourne **pas en root** : un utilisateur `appuser` dédié est
créé, et les fichiers d'exécution lui appartiennent (`--chown`).

---

## 📂 Structure

```
.
├── app/
│   ├── __init__.py
│   ├── main.py          # L'API REST FastAPI
│   └── config.py        # Config via variables d'environnement
├── Dockerfile           # Multi-stage : builder (uv) + runtime (slim, non-root)
├── .dockerignore        # Ce qui ne rentre pas dans l'image
├── docker-compose.yml   # Build + run + healthcheck
├── pyproject.toml       # Dépendances gérées par uv
├── .env.example         # Template de config (versionné)
├── .env                 # Config locale (NON versionnée)
└── .gitignore
```

---

## 📝 Licence

MIT — librement réutilisable.
