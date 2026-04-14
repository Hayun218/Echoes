import importlib
import os
import tempfile
from datetime import datetime
from pathlib import Path
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session as DBSession

from app.models.base import Base
from app.models.character import Character
from app.models.message import Message
from app.models.profile import Profile
from app.models.scene import Scene
from app.models.session import Session as StorySession


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
def profile_id() -> str:
    return "00000000-0000-0000-0000-000000000001"


@pytest.fixture
def scene_data(use_test_database, profile_id: str):
    engine = use_test_database
    now = datetime.utcnow()
    character_id = str(uuid4())
    free_scene_id = str(uuid4())
    premium_scene_id = str(uuid4())

    with DBSession(engine) as session:
        character = Character(
            id=character_id,
            slug="test-character",
            name="Test Character",
            description="A test character.",
            tags=["hero", "test"],
            sort_order=1,
            is_active=True,
            is_featured=False,
        )
        session.add(character)

        profile = Profile(
            id=profile_id,
            status="active",
            preferences={},
            created_at=now,
            updated_at=now,
        )
        session.add(profile)

        second_profile_id = "00000000-0000-0000-0000-000000000002"
        second_profile = Profile(
            id=second_profile_id,
            status="active",
            preferences={},
            created_at=now,
            updated_at=now,
        )
        session.add(second_profile)

        free_scene = Scene(
            id=free_scene_id,
            character_id=character_id,
            slug="free-scene",
            title="Free Scene",
            description="A free public scene.",
            intro_text="Intro to free scene.",
            prompt_template="Prompt for free scene.",
            mood_tags=["reflective"],
            difficulty_level=2,
            access_tier="free",
            is_public_browse=True,
            is_active=True,
            sort_order=1,
        )
        session.add(free_scene)

        premium_scene = Scene(
            id=premium_scene_id,
            character_id=character_id,
            slug="premium-scene",
            title="Premium Scene",
            description="A premium scene.",
            intro_text="Intro to premium scene.",
            prompt_template="Prompt for premium scene.",
            mood_tags=["heroic"],
            difficulty_level=4,
            access_tier="premium",
            is_public_browse=True,
            is_active=True,
            sort_order=2,
        )
        session.add(premium_scene)
        session.commit()

    return {
        "profile_id": profile_id,
        "second_profile_id": second_profile_id,
        "free_scene_id": free_scene_id,
        "premium_scene_id": premium_scene_id,
    }


def test_start_with_explicit_scene_id(client: TestClient, scene_data: dict):
    response = client.post(
        "/api/v1/sessions/start",
        headers={"X-Profile-Id": scene_data["profile_id"]},
        json={
            "concept": "Explore courage in the palace.",
            "scene_id": scene_data["premium_scene_id"],
            "theme": "heroic",
            "tone": "bold",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["session_id"]
    assert payload["scene"]["id"] == scene_data["premium_scene_id"]
    assert payload["scene"]["intro_text"] == "Intro to premium scene."
    assert payload["story_metadata"] == {
        "concept": "Explore courage in the palace.",
        "theme": "heroic",
        "tone": "bold",
    }
    assert payload["progression_state"]["stage"] == "started"
    assert payload["progression_state"]["concept"] == "Explore courage in the palace."
    assert payload["intro_text"] == "Intro to premium scene."


def test_start_without_scene_id_selects_default_free_scene(client: TestClient, scene_data: dict):
    response = client.post(
        "/api/v1/sessions/start",
        headers={"X-Profile-Id": scene_data["profile_id"]},
        json={
            "concept": "Begin a reflective journey.",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["scene"]["access_tier"] == "free"
    assert payload["scene"]["slug"] == "free-scene"
    assert payload["story_metadata"]["concept"] == "Begin a reflective journey."
    assert payload["progression_state"]["stage"] == "started"


def test_invalid_profile_id_returns_401(client: TestClient):
    response = client.post(
        "/api/v1/sessions/start",
        headers={"X-Profile-Id": "00000000-0000-0000-0000-000000000099"},
        json={"concept": "Should fail."},
    )

    assert response.status_code == 401
    assert response.json()["detail"] == "Authenticated profile not found"


def test_response_shape_includes_scene_and_session_fields(client: TestClient, scene_data: dict):
    response = client.post(
        "/api/v1/sessions/start",
        headers={"X-Profile-Id": scene_data["profile_id"]},
        json={"concept": "Check response shape."},
    )

    assert response.status_code == 200
    payload = response.json()
    assert set(payload.keys()) == {
        "session_id",
        "scene",
        "story_metadata",
        "progression_state",
        "intro_text",
    }
    assert payload["scene"]["title"] == "Free Scene"
    assert payload["intro_text"] == "Intro to free scene."


def test_add_session_turn_returns_short_scene_block(
    client: TestClient,
    scene_data: dict,
    use_test_database,
):
    start_response = client.post(
        "/api/v1/sessions/start",
        headers={"X-Profile-Id": scene_data["profile_id"]},
        json={"concept": "Explore a hopeful moment."},
    )
    assert start_response.status_code == 200
    session_id = start_response.json()["session_id"]

    turn_response = client.post(
        f"/api/v1/sessions/{session_id}/turns",
        headers={"X-Profile-Id": scene_data["profile_id"]},
        json={"user_input": "I urge the character to trust the path."},
    )

    assert turn_response.status_code == 200
    payload = turn_response.json()
    assert payload["session_id"] == session_id
    assert payload["scene_id"] == start_response.json()["scene"]["id"]
    assert payload["turn_id"]
    assert isinstance(payload["next_block"], str)
    assert "You say" in payload["next_block"]
    assert payload["is_complete"] is False
    assert payload["progression_state"]["turn_count"] == 1
    assert payload["progression_state"]["last_user_input"] == "I urge the character to trust the path."

    with DBSession(use_test_database) as db:
        messages = db.query(Message).filter(Message.session_id == session_id).order_by(Message.created_at).all()
        assert len(messages) == 2
        assert messages[0].sender_type == "user"
        assert messages[0].content == "I urge the character to trust the path."
        assert messages[1].sender_type == "ai"
        assert "You say" in messages[1].content


def test_add_session_turn_invalid_session_returns_404(client: TestClient, scene_data: dict):
    response = client.post(
        "/api/v1/sessions/00000000-0000-0000-0000-000000000099/turns",
        headers={"X-Profile-Id": scene_data["profile_id"]},
        json={"user_input": "Hello"},
    )
    assert response.status_code == 404
    assert response.json()["detail"] == "Session not found"


def test_get_session_messages_returns_ordered_messages_and_expected_shape(
    client: TestClient,
    scene_data: dict,
):
    start_response = client.post(
        "/api/v1/sessions/start",
        headers={"X-Profile-Id": scene_data["profile_id"]},
        json={"concept": "Begin the message history test."},
    )
    assert start_response.status_code == 200
    session_id = start_response.json()["session_id"]

    first_turn = client.post(
        f"/api/v1/sessions/{session_id}/turns",
        headers={"X-Profile-Id": scene_data["profile_id"]},
        json={"user_input": "First user choice."},
    )
    assert first_turn.status_code == 200

    second_turn = client.post(
        f"/api/v1/sessions/{session_id}/turns",
        headers={"X-Profile-Id": scene_data["profile_id"]},
        json={"user_input": "Second user choice."},
    )
    assert second_turn.status_code == 200

    response = client.get(
        f"/api/v1/sessions/{session_id}/messages",
        headers={"X-Profile-Id": scene_data["profile_id"]},
    )

    assert response.status_code == 200
    payload = response.json()
    assert len(payload) == 4

    expected_keys = {
        "id",
        "session_id",
        "sender_type",
        "speaker_type",
        "speaker_character_id",
        "content",
        "created_at",
    }
    assert set(payload[0].keys()) == expected_keys
    assert payload[0]["session_id"] == session_id
    assert payload[0]["sender_type"] == "user"
    assert payload[1]["sender_type"] == "ai"
    assert payload[2]["sender_type"] == "user"
    assert payload[3]["sender_type"] == "ai"
    assert payload[0]["content"] == "First user choice."
    assert payload[2]["content"] == "Second user choice."

    created_times = [item["created_at"] for item in payload]
    assert created_times == sorted(created_times)


def test_get_session_messages_forbidden_with_invalid_profile(
    client: TestClient,
    scene_data: dict,
):
    start_response = client.post(
        "/api/v1/sessions/start",
        headers={"X-Profile-Id": scene_data["profile_id"]},
        json={"concept": "Verify profile validation."},
    )
    assert start_response.status_code == 200
    session_id = start_response.json()["session_id"]

    response = client.get(
        f"/api/v1/sessions/{session_id}/messages",
        headers={"X-Profile-Id": "00000000-0000-0000-0000-000000000099"},
    )

    assert response.status_code == 403
    assert response.json()["detail"] == "Forbidden"


def test_get_sessions_list_returns_owned_sessions_ordered_and_shaped(
    client: TestClient,
    scene_data: dict,
):
    first_response = client.post(
        "/api/v1/sessions/start",
        headers={"X-Profile-Id": scene_data["profile_id"]},
        json={"concept": "First story."},
    )
    assert first_response.status_code == 200
    first_session_id = first_response.json()["session_id"]

    other_response = client.post(
        "/api/v1/sessions/start",
        headers={"X-Profile-Id": scene_data["second_profile_id"]},
        json={"concept": "Other profile story."},
    )
    assert other_response.status_code == 200

    second_response = client.post(
        "/api/v1/sessions/start",
        headers={"X-Profile-Id": scene_data["profile_id"]},
        json={"concept": "Second story."},
    )
    assert second_response.status_code == 200
    second_session_id = second_response.json()["session_id"]

    list_response = client.get(
        "/api/v1/sessions",
        headers={"X-Profile-Id": scene_data["profile_id"]},
    )
    assert list_response.status_code == 200
    payload = list_response.json()
    assert len(payload) == 2
    assert payload[0]["session_id"] == second_session_id
    assert payload[1]["session_id"] == first_session_id
    assert payload[0]["status"] == "active"
    assert payload[0]["source_type"] == "canonical"
    assert payload[0]["scene_title"] == "Free Scene"
    assert payload[0]["primary_character_name"] == "Test Character"
    assert payload[0]["last_scene_block_preview"] is None

    expected_keys = {
        "session_id",
        "scene_id",
        "scene_title",
        "primary_character_id",
        "primary_character_name",
        "status",
        "source_type",
        "updated_at",
        "is_complete",
        "last_scene_block_preview",
    }
    assert set(payload[0].keys()) == expected_keys
    assert payload[0]["session_id"] != other_response.json()["session_id"]


def test_get_session_detail_returns_resume_metadata_for_owned_session(
    client: TestClient,
    scene_data: dict,
):
    start_response = client.post(
        "/api/v1/sessions/start",
        headers={"X-Profile-Id": scene_data["profile_id"]},
        json={"concept": "Session detail resume."},
    )
    assert start_response.status_code == 200
    session_id = start_response.json()["session_id"]

    detail_response = client.get(
        f"/api/v1/sessions/{session_id}",
        headers={"X-Profile-Id": scene_data["profile_id"]},
    )

    assert detail_response.status_code == 200
    detail_payload = detail_response.json()
    assert detail_payload["session_id"] == session_id
    assert detail_payload["scene_title"] == "Free Scene"
    assert detail_payload["scene_intro_text"] == "Intro to free scene."
    assert detail_payload["primary_character_name"] == "Test Character"
    assert detail_payload["status"] == "active"
    assert detail_payload["source_type"] == "canonical"
    assert detail_payload["is_complete"] is False
    assert detail_payload["story_metadata"]["concept"] == "Session detail resume."
    assert detail_payload["progression_state"]["stage"] == "started"
    assert detail_payload["last_scene_block_preview"] is None


def test_get_session_detail_forbidden_for_other_profile(
    client: TestClient,
    scene_data: dict,
):
    start_response = client.post(
        "/api/v1/sessions/start",
        headers={"X-Profile-Id": scene_data["profile_id"]},
        json={"concept": "Protected detail."},
    )
    assert start_response.status_code == 200
    session_id = start_response.json()["session_id"]

    response = client.get(
        f"/api/v1/sessions/{session_id}",
        headers={"X-Profile-Id": scene_data["second_profile_id"]},
    )
    assert response.status_code == 403
    assert response.json()["detail"] == "Forbidden"
