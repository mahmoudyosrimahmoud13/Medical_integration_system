"""Pharmacy and hospital roles, share codes, CT scans and the full medical record."""


async def _login(client, email, password):
    r = await client.post("/api/v1/auth/login", json={"login": email, "password": password})
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


async def _new_user(client, refs, n: int):
    body = {
        "name": f"Facility Owner {n}", "email": f"owner{n}@test.local", "password": "Owner@12345",
        "phone": f"0155{n:07d}", "birth_date": "1985-01-01", "national_id": f"2850101{n:07d}",
        "gender": "male", "area_id": str(refs["area"].id),
    }
    assert (await client.post("/api/v1/auth/register", json=body)).status_code == 201
    return await _login(client, body["email"], body["password"])


async def test_find_pharmacy_with_drug_and_fill_by_code(client, refs):
    # demo pharmacy stocks Acetaminophen (DB00316)
    found = (await client.get("/api/v1/pharmacies", params={"drug_id": "DB00316"})).json()
    assert found[0]["name"] == "El Nour Pharmacy" and found[0]["item"]["quantity"] == 120
    assert (await client.get("/api/v1/pharmacies", params={"drug_id": "DB00807"})).json() == []

    # doctor prescribes, patient makes a share code, pharmacy reads the prescription with it
    doctor = await _login(client, "doctor@healthhub.local", "Doctor@12345")
    patient = await _login(client, "patient@healthhub.local", "Patient@12345")
    s = await client.post("/api/v1/medical/sessions", headers=doctor, json={
        "patient_email": "patient@healthhub.local", "disease_name": "Flu",
        "prescriptions": [{"drug_id": "DB00316", "repeat": "every 8 hours", "repeat_count": 3, "end_date": "2099-01-01"}],
    })
    assert s.status_code == 201, s.text
    code = (await client.post("/api/v1/medical/share-code", headers=patient)).json()["code"]
    pharmacy = await _login(client, "pharmacy@healthhub.local", "Pharmacy@12345")
    shared = await client.get("/api/v1/pharmacies/me/prescriptions", params={"code": code.lower()}, headers=pharmacy)
    assert shared.status_code == 200, shared.text
    assert shared.json()["patient_name"] == "Sara Ali"
    assert any(p["drug_id"] == "DB00316" for p in shared.json()["prescriptions"])
    # a patient can't use the pharmacy route
    assert (await client.get("/api/v1/pharmacies/me/prescriptions", params={"code": code}, headers=patient)).status_code == 403


async def test_pharmacy_application_and_stock(client, refs):
    owner = await _new_user(client, refs, 1)
    r = await client.post("/api/v1/pharmacies/apply", headers=owner,
                          json={"name": "New Life Pharmacy", "area_id": str(refs["area"].id), "phone": "01099999999"})
    assert r.status_code == 201 and r.json()["status"] == "pending"
    assert (await client.put("/api/v1/pharmacies/me/stock", headers=owner,
                             json={"drug_id": "DB01050", "quantity": 5, "price": 10})).status_code == 403

    admin = await _login(client, "admin@healthhub.local", "Admin@12345")
    pending = (await client.get("/api/v1/admin/pharmacy-requests", headers=admin)).json()
    pid = next(p["id"] for p in pending if p["name"] == "New Life Pharmacy")
    assert (await client.post(f"/api/v1/admin/pharmacy-requests/{pid}/accept", headers=admin)).json()["status"] == "accepted"

    me = (await client.get("/api/v1/pharmacies/me", headers=owner)).json()
    assert me["status"] == "accepted" and me["access_token"]
    item = await client.put("/api/v1/pharmacies/me/stock", headers=owner, json={"drug_id": "DB01050", "quantity": 5, "price": 10})
    assert item.json()["drug_name"] == "Ibuprofen"
    assert len((await client.get("/api/v1/pharmacies/me/stock", headers=owner)).json()) == 1
    assert (await client.delete("/api/v1/pharmacies/me/stock/DB01050", headers=owner)).status_code == 200


async def test_hospital_flow(client, refs):
    listed = (await client.get("/api/v1/hospitals")).json()
    demo = next(h for h in listed if h["name"] == "Dar El Shifa Hospital")
    assert demo["doctors"][0]["department"] == "Cardiology"

    owner = await _new_user(client, refs, 2)
    r = await client.post("/api/v1/hospitals/apply", headers=owner,
                          json={"name": "Hope Clinic Hospital", "area_id": str(refs["area"].id), "description": "Small"})
    assert r.status_code == 201
    admin = await _login(client, "admin@healthhub.local", "Admin@12345")
    hid = next(h["id"] for h in (await client.get("/api/v1/admin/hospital-requests", headers=admin)).json() if h["name"] == "Hope Clinic Hospital")
    await client.post(f"/api/v1/admin/hospital-requests/{hid}/accept", headers=admin)

    added = await client.post("/api/v1/hospitals/me/doctors", headers=owner,
                              json={"doctor_email": "doctor@healthhub.local", "department": "Heart unit"})
    assert added.status_code == 200, added.text
    assert added.json()["doctors"][0]["doctor"]["name"] == "Ahmed Hassan"
    bad = await client.post("/api/v1/hospitals/me/doctors", headers=owner, json={"doctor_email": "patient@healthhub.local"})
    assert bad.status_code == 404
    assert (await client.get("/api/v1/hospitals/me/appointments", headers=owner)).status_code == 200


async def test_ct_scan_and_full_record(client):
    patient = await _login(client, "patient@healthhub.local", "Patient@12345")
    png = (await client.get("/Image/User/default.png")).content
    up = await client.post("/api/v1/medical/ct-scans", headers=patient, files={"file": ("scan.png", png, "image/png")})
    assert up.status_code == 201, up.text
    record = (await client.get("/api/v1/medical/record", headers=patient)).json()
    assert record["patient"]["name"] == "Sara Ali" and record["ct_scans"] and record["sessions"]

    doctor = await _login(client, "doctor@healthhub.local", "Doctor@12345")
    seen = await client.get("/api/v1/medical/patients/patient@healthhub.local/record", headers=doctor)
    assert seen.status_code == 200 and seen.json()["ct_scans"]
    assert (await client.get("/api/v1/medical/patients/doctor@healthhub.local/record", headers=patient)).status_code == 403
