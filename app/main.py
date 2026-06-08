"""API REST minimale en FastAPI, pensée pour une image Docker optimisée."""

from __future__ import annotations

from datetime import datetime, timezone

from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel, Field

from app.config import settings

app = FastAPI(
    title=settings.app_name,
    description="API REST de démonstration pour un Dockerfile optimisé (uv, multi-stage, slim).",
    version="1.0.0",
)


# --- Modèles ---------------------------------------------------------------


class Item(BaseModel):
    id: int
    name: str = Field(..., min_length=1, max_length=100)
    description: str | None = None


class ItemCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: str | None = None


# --- "Base de données" en mémoire ------------------------------------------

_items: dict[int, Item] = {}
_next_id = 1


# --- Routes ----------------------------------------------------------------


@app.get("/")
def root() -> dict[str, str]:
    return {"message": f"Bienvenue sur {settings.app_name}", "env": settings.environment}


@app.get("/health")
def health() -> dict[str, str]:
    """Endpoint de healthcheck (utilisé par docker-compose)."""
    return {
        "status": "ok",
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@app.get("/items", response_model=list[Item])
def list_items() -> list[Item]:
    return list(_items.values())


@app.get("/items/{item_id}", response_model=Item)
def get_item(item_id: int) -> Item:
    item = _items.get(item_id)
    if item is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Item introuvable"
        )
    return item


@app.post("/items", response_model=Item, status_code=status.HTTP_201_CREATED)
def create_item(payload: ItemCreate) -> Item:
    global _next_id
    item = Item(id=_next_id, name=payload.name, description=payload.description)
    _items[_next_id] = item
    _next_id += 1
    return item


@app.delete("/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_item(item_id: int) -> None:
    if item_id not in _items:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Item introuvable"
        )
    del _items[item_id]
