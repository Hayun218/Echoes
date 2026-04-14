import importlib
from datetime import datetime
from pathlib import Path
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session as DBSession

from app.models.base import Base
from app.models.character import Character
from app.models.scene import Scene


@pytest.fixture(autouse=True)
def use_test_database(monkeypatch, tmp_path: Path):
    db_file = tmp_path / "test_echoes.db"
    monkeypatch.setenv("DATABASE_URL", f"sqlite:///{db_file}")

    db_module = importlib.import_module("app.db")
    engine = db_module.engine

    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    yield engine
    Base.metadata.drop_all(bind=engine)


@pytest.fixture
def client(use_test_database) -> TestClient:
    app_module = importlib.import_module("app.main")
    return TestClient(app_module.app)


@pytest.fixture
def scene_and_character_data(use_test_database):
    engine = use_test_database
    now = datetime.utcnow()
    character_id = str(uuid4())
    public_scene_id = str(uuid4())
    private_scene_id = str(uuid4())

    with DBSession(engine) as session:
        character = Character(
            id=character_id,
            slug="john",
            name="John",
            description="A test character for read endpoint tests.",
            tags=["leader", "faith"],
            sort_order=1,
            is_active=True,
            is_featured=False,
        )
        session.add(character)

        public_scene = Scene(
            id=public_scene_id,
            character_id=character_id,
            slug="john-mission",
            title="Mission Moment",
            description="A public browse mission scene.",
            intro_text="John steps into a new mission.",
            prompt_template="Set the mission scene.",
            mood_tags=["adventurous"],
            difficulty_level=2,
            access_tier="free",
            is_public_browse=True,
            is_active=True,
            sort_order=1,
        )
        session.add(public_scene)

        private_scene = Scene(
            id=private_scene_id,
            character_id=character_id,
            slug="john-secret",
            title="Hidden Moment",
            description="A private premium scene.",
            intro_text="John prepares in secret.",
            prompt_template="Set the secret scene.",
            mood_tags=["introspective"],
            difficulty_level=4,
            access_tier="premium",
            is_public_browse=False,
            is_active=True,
            sort_order=2,
        )
        session.add(private_scene)
        session.commit()

    return {
        "character_id": character_id,
        "public_scene_id": public_scene_id,
        "private_scene_id": private_scene_id,
    }


def test_get_characters_returns_active_characters(client: TestClient, scene_and_character_data: dict):
    response = client.get("/api/v1/characters")
    assert response.status_code == 200
    payload = response.json()
    assert isinstance(payload, list)
    assert len(payload) == 1
    assert payload[0]["slug"] == "john"
    assert payload[0]["is_active"] is True


def test_get_character_by_id_returns_character(client: TestClient, scene_and_character_data: dict):
    response = client.get(f"/api/v1/characters/{scene_and_character_data['character_id']}")
    assert response.status_code == 200
    payload = response.json()
    assert payload["slug"] == "john"
    assert payload["name"] == "John"


def test_get_scenes_returns_public_browse_scenes(client: TestClient, scene_and_character_data: dict):
    response = client.get("/api/v1/scenes")
    assert response.status_code == 200
    payload = response.json()
    assert isinstance(payload, list)
    assert len(payload) == 1

    scene = payload[0]
    assert scene["slug"] == "john-mission"
    assert scene["access_tier"] == "free"
    assert scene["is_public_browse"] is True
    assert scene["character"]["slug"] == "john"


def test_get_scene_by_id_returns_scene_detail(client: TestClient, scene_and_character_data: dict):
    response = client.get(f"/api/v1/scenes/{scene_and_character_data['public_scene_id']}")
    assert response.status_code == 200
    payload = response.json()
    assert payload["slug"] == "john-mission"
    assert payload["prompt_template"] == "Set the mission scene."
    assert payload["character"]["name"] == "John"


def test_get_scene_detail_includes_access_tier_and_browse_flag(client: TestClient, scene_and_character_data: dict):
    response = client.get(f"/api/v1/scenes/{scene_and_character_data['public_scene_id']}")
    payload = response.json()
    assert payload["access_tier"] == "free"
    assert payload["is_public_browse"] is True
