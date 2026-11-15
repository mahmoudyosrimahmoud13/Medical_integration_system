"""The backend talks to the AI service (AI/ddi_service) and falls back to the 2024 Flask contract."""

import httpx
import pytest

from app.core.config import settings
from app.ml import client as ml


async def _login(client, email, password):
    r = await client.post("/api/v1/auth/login", json={"login": email, "password": password})
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


def _fake_service(handler):
    real = httpx.AsyncClient

    def make(*args, **kwargs):
        kwargs["transport"] = httpx.MockTransport(handler)
        return real(*args, **kwargs)

    return make


@pytest.fixture
def ml_on(monkeypatch):
    monkeypatch.setattr(settings, "ml_service_url", "http://ai.test")
    return monkeypatch


async def test_check_uses_new_service_and_caches(client, ml_on):
    calls = []

    def handler(request: httpx.Request):
        calls.append(request.url.path)
        body = __import__("json").loads(request.content)
        assert body["drug_1_name"] and body["drug_1_id"].startswith("DB")
        return httpx.Response(200, json={"interacts": True, "source": "drugbank", "type": 45,
                                         "description": "Acetylsalicylic acid may increase the anticoagulant activities of Warfarin."})

    ml_on.setattr(ml.httpx, "AsyncClient", _fake_service(handler))
    doctor = await _login(client, "doctor@healthhub.local", "Doctor@12345")
    s = await client.post("/api/v1/medical/sessions", headers=doctor, json={
        "patient_email": "patient@healthhub.local", "disease_name": "Atrial fibrillation",
        "prescriptions": [{"drug_id": "DB00682", "repeat": "once daily", "repeat_count": 1, "end_date": "2099-01-01"}],
    })
    assert s.status_code == 201, s.text
    body = {"patient_email": "patient@healthhub.local", "drug_ids": ["DB00945"]}
    r = await client.post("/api/v1/medical/interactions/check", headers=doctor, json=body)
    assert r.status_code == 200, r.text
    out = r.json()
    assert out["available"] is True and out["impact"] is True
    hit = next(x for x in out["results"] if {x["drugA"], x["drugB"]} == {"Acetylsalicylic acid", "Warfarin"})
    assert "anticoagulant" in hit["description"]
    n = len(calls)
    await client.post("/api/v1/medical/interactions/check", headers=doctor, json=body)
    assert len(calls) == n  # second time comes from the cache


async def test_falls_back_to_old_flask_contract(client, ml_on):
    def handler(request: httpx.Request):
        if request.url.path == "/v1/check":
            return httpx.Response(404)
        assert request.url.path == "/CheckInteraction"
        return httpx.Response(200, json={"InteractionResult": False, "InteractionNameIndex": -1})

    ml_on.setattr(ml.httpx, "AsyncClient", _fake_service(handler))
    doctor = await _login(client, "doctor@healthhub.local", "Doctor@12345")
    r = await client.post("/api/v1/medical/interactions/check", headers=doctor,
                          json={"patient_email": "patient@healthhub.local", "drug_ids": ["DB00316", "DB01050"]})
    pair = next(x for x in r.json()["results"] if {x["drugA"], x["drugB"]} == {"Acetaminophen", "Ibuprofen"})
    assert pair["interacts"] is False and pair["description"] == "No interaction found"
