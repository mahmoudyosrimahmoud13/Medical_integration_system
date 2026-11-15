"""Messaging rules between roles, and the Egyptian product catalogue."""

from tests.conftest import next_weekday


async def _login(client, email, password="Patient@12345"):
    r = await client.post("/api/v1/auth/login", json={"login": email, "password": password})
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['access_token']}"}, r.json()["user"]


async def _new_patient(client, refs, n):
    body = {"name": f"Chat Patient {n}", "email": f"chat{n}@test.local", "password": "Patient@12345", "phone": f"0122{n:07d}",
            "birth_date": "1990-01-01", "national_id": f"2900101{n:07d}", "gender": "male", "area_id": str(refs["area"].id)}
    assert (await client.post("/api/v1/auth/register", json=body)).status_code == 201
    return await _login(client, body["email"])


async def test_patient_can_message_doctor_only_after_booking(client, refs):
    ph, patient = await _new_patient(client, refs, 1)
    dh, doctor_user = await _login(client, "doctor@healthhub.local", "Doctor@12345")

    blocked = await client.post("/api/v1/chat/conversations", json={"user_id": doctor_user["id"]}, headers=ph)
    assert blocked.status_code == 403
    assert "booking" in blocked.json()["detail"]

    doc = next(d for d in (await client.get("/api/v1/doctors", params={"name": "Ahmed"})).json()["items"] if d["name"] == "Ahmed Hassan")
    day = next_weekday("Monday")
    assert (await client.post("/api/v1/appointments", json={"doctor_id": doc["id"], "day": day.isoformat(), "time_from": "11:00 AM"}, headers=ph)).status_code == 201

    started = await client.post("/api/v1/chat/conversations", json={"user_id": doctor_user["id"], "subject": "Before my visit", "first_message": "Should I fast?"}, headers=ph)
    assert started.status_code == 201, started.text
    conv = started.json()
    assert conv["other"]["name"] == "Ahmed Hassan" and conv["other_role"] == "Doctor"

    # doctor sees it unread, reads it, replies
    mine = (await client.get("/api/v1/chat/conversations", headers=dh)).json()
    row = next(c for c in mine if c["id"] == conv["id"])
    assert row["unread"] == 1 and row["other"]["name"] == patient["name"]
    assert (await client.get("/api/v1/chat/unread", headers=dh)).json()["unread"] >= 1
    msgs = (await client.get(f"/api/v1/chat/conversations/{conv['id']}/messages", headers=dh)).json()
    assert msgs[0]["text"] == "Should I fast?" and msgs[0]["mine"] is False
    reply = await client.post(f"/api/v1/chat/conversations/{conv['id']}/messages", json={"text": "No need, come as usual."}, headers=dh)
    assert reply.status_code == 201
    assert (await client.get("/api/v1/chat/conversations", headers=dh)).json()[0]["unread"] == 0

    # patient gets a notification and sees the reply
    notes = (await client.get("/api/v1/notifications", headers=ph)).json()
    assert any("message" in n["message"].lower() for n in notes)
    msgs = (await client.get(f"/api/v1/chat/conversations/{conv['id']}/messages", headers=ph)).json()
    assert [m["text"] for m in msgs] == ["Should I fast?", "No need, come as usual."]

    # a stranger cannot read it
    sh, _ = await _new_patient(client, refs, 2)
    assert (await client.get(f"/api/v1/chat/conversations/{conv['id']}/messages", headers=sh)).status_code == 404
    assert (await client.post("/api/v1/chat/conversations", json={"user_id": patient["id"]}, headers=sh)).status_code == 403


async def test_patient_can_ask_a_pharmacy_but_pharmacy_cannot_cold_message(client, refs):
    ph, patient = await _new_patient(client, refs, 3)
    pharm_h, pharm_user = await _login(client, "pharmacy@healthhub.local", "Pharmacy@12345")
    assert (await client.post("/api/v1/chat/conversations", json={"user_id": patient["id"]}, headers=pharm_h)).status_code == 403
    r = await client.post("/api/v1/chat/conversations", json={"user_id": pharm_user["id"], "first_message": "Do you have Concor?"}, headers=ph)
    assert r.status_code == 201 and r.json()["other_role"] == "Pharmacy"
    # now the pharmacy can reply in that conversation
    assert (await client.post(f"/api/v1/chat/conversations/{r.json()['id']}/messages", json={"text": "Yes, 90 EGP."}, headers=pharm_h)).status_code == 201
    contacts = (await client.get("/api/v1/chat/contacts", headers=pharm_h)).json()
    assert any(c["name"] == patient["name"] for c in contacts)


async def test_hospital_and_its_doctor_can_talk(client):
    hh, _ = await _login(client, "hospital@healthhub.local", "Hospital@12345")
    contacts = (await client.get("/api/v1/chat/contacts", headers=hh)).json()
    doc = next(c for c in contacts if c["role"] == "Doctor")
    r = await client.post("/api/v1/chat/conversations", json={"user_id": doc["user_id"], "first_message": "Clinic moves to floor 3."}, headers=hh)
    assert r.status_code == 201


async def test_contacts_include_support(client, refs):
    ph, _ = await _new_patient(client, refs, 4)
    contacts = (await client.get("/api/v1/chat/contacts", headers=ph)).json()
    assert any(c["role"] == "Support" for c in contacts)


async def test_message_validation(client, refs):
    ph, patient = await _new_patient(client, refs, 5)
    pharm_h, pharm_user = await _login(client, "pharmacy@healthhub.local", "Pharmacy@12345")
    conv = (await client.post("/api/v1/chat/conversations", json={"user_id": pharm_user["id"]}, headers=ph)).json()
    assert (await client.post(f"/api/v1/chat/conversations/{conv['id']}/messages", json={"text": "   "}, headers=ph)).status_code in (400, 422)
    assert (await client.post(f"/api/v1/chat/conversations/{conv['id']}/messages", json={"text": "x" * 2001}, headers=ph)).status_code == 422


async def test_egyptian_products(client):
    panadol = (await client.get("/api/v1/products", params={"q": "panadol"})).json()
    assert panadol and panadol[0]["active_ingredient"] == "Acetaminophen" and panadol[0]["manufacturer"] == "GSK Egypt"
    by_ingredient = (await client.get("/api/v1/products", params={"q": "metformin"})).json()
    assert {p["brand"] for p in by_ingredient} >= {"Glucophage", "Cidophage"}
    cats = (await client.get("/api/v1/products/categories")).json()
    assert "Diabetes" in cats and "Antibiotics" in cats
    diabetes = (await client.get("/api/v1/products", params={"category": "diabetes"})).json()
    assert all(p["category"] == "Diabetes" for p in diabetes) and len(diabetes) >= 8
    rx = next(p for p in (await client.get("/api/v1/products", params={"q": "augmentin"})).json())
    assert rx["prescription_only"] is True

    # the demo pharmacies stock real ingredients, so a patient can find Concor's ingredient somewhere
    found = (await client.get("/api/v1/pharmacies", params={"drug_id": panadol[0]["drug_id"]})).json()
    assert found, "at least one demo pharmacy should have acetaminophen"
