"""Doctor side (React app routes) and the clean /api/v1 routes."""

import json

from tests.conftest import legacy_token, next_weekday, unique_patient

DOCTOR = ("doctor@healthhub.local", "Doctor@12345")
ADMIN = ("admin@healthhub.local", "Admin@12345")


async def _patient(client, refs):
    data = unique_patient() | {"area": refs["area"].key}
    assert (await client.post("/Auth/Register", data={"input": json.dumps(data)})).json()["error"] is False
    return data, {"Authorization": f"Bearer {await legacy_token(client, data['email'], data['password'])}"}


async def test_medical_session_and_prescriptions(client, refs):
    patient, ph = await _patient(client, refs)
    dh = {"Authorization": f"Bearer {await legacy_token(client, *DOCTOR)}"}

    drug = (await client.get("/Hospital/Drug/SerchByName", params={"name": "warfarin"})).json()[0]
    r = await client.post(
        "/Hospital/Doctor/MedicalSession",
        json={
            "sessionnote": "Follow up in 2 weeks",
            "diseaseName": "Hypertension",
            "patientEmail": patient["email"],
            "persistent": True,
            "diseasnote": "Mild",
            "Cured": False,
            "repentances": [{"drugId": drug["id"], "note": "after food", "repeat": "daily", "repeatCount": 1,
                             "startDate": "2026-01-01", "endDate": "2099-01-01"}],
        },
        headers=dh,
    )
    assert r.json() == "Save", r.text

    rx = (await client.get("/Hospital/Patient/Information/Repentances", headers=ph)).json()
    assert rx[0]["dcotorName"] == "Ahmed Hassan" and rx[0]["diseaseName"] == "Hypertension"
    line = rx[0]["repentances"][0]
    assert line["drugName"] == drug["name"] and line["startdate"] == "2026-01-01" and line["note"] == "after food"

    current = (await client.get("/Hospital/Patient/information/GetCurrentDrugs", headers=ph)).json()
    assert current[0]["drugId"] == drug["id"]

    # ML not configured: the check answers instead of crashing
    other = (await client.get("/Hospital/Drug/SerchByName", params={"name": "ibuprofen"})).json()[0]
    check = await client.post(
        "/Hospital/Doctor/MedicalSession/CheackDrugsInteraction", params={"PaientEmail": patient["email"]},
        json=[other["id"]], headers=dh,
    )
    assert check.json()["impact"] is False and "not available" in check.json()["interactionResult"][0]

    notes = (await client.get("/api/Notification", headers=ph)).json()
    assert any("prescription" in n["message"] for n in notes)


async def test_patient_cannot_use_doctor_routes(client, refs):
    _, ph = await _patient(client, refs)
    assert (await client.get("/Hospital/Doctor/BookedAppointments", headers=ph)).status_code == 403


async def test_doctor_application_and_admin_review(client, refs):
    patient, ph = await _patient(client, refs)
    form = {"input": json.dumps({"areaClinicId": str(refs["area"].id), "graduationYear": "2015-06-01T00:00:00",
                                 "CollegeName": "Ain Shams", "SummaryCareer": "GP", "AddressDescrption": "Nasr City",
                                 "specialtieId": str(refs["cardiology"].id)})}
    pdf = ("cert.pdf", b"%PDF-1.4 test", "application/pdf")
    r = await client.post("/Hospital/Doctor/AddDoctor", data=form, files=[("Certificates", pdf)], headers=ph)
    assert r.json()["error"] is False, r.text

    status = (await client.get("/Hospital/Doctor/CheackRoleDoctor", headers=ph)).json()
    assert status["message"] == "Your Request Has Not Yet been Reviewed"

    ah = {"Authorization": f"Bearer {await legacy_token(client, *ADMIN)}"}
    pending = (await client.get("/Hospital/Doctor/GetDoctorsNotActive", params={"index": 0}, headers=ah)).json()
    mine = next(d for d in pending["doctors"] if d["email"] == patient["email"])
    assert mine["certificates"][0]["src"].endswith(".pdf")
    assert (await client.put("/Hospital/Doctor/ActionDoctor", params={"Id": mine["id"], "action": "true"}, headers=ah)).json() is True

    accepted = (await client.get("/Hospital/Doctor/CheackRoleDoctor", headers=ph)).json()
    assert accepted["message"] == "Accept" and "Doctor" in accepted["roles"]
    nh = {"Authorization": f"Bearer {accepted['token']}"}

    assert (await client.post("/Hospital/Doctor/AddAppointmentBook",
                              json=[{"dayName": "Sunday", "from": "10:00 AM", "to": "02:00 PM"}], headers=nh)).json() == "Save"
    assert (await client.put("/Hospital/Doctor/EditAppointmentBook", params={"OldDayName": "Sunday"},
                             json={"dayName": "Sunday", "from": "11:00 AM", "to": "03:00 PM"}, headers=nh)).json() == "Save Change"
    dates = (await client.get("/Hospital/Doctor/DoctorDates", headers=nh)).json()
    assert dates == [{"dayName": "Sunday", "from": "11:00 AM", "to": "03:00 PM"}]


async def test_doctor_sees_and_cancels_booking(client, refs):
    patient, ph = await _patient(client, refs)
    dh = {"Authorization": f"Bearer {await legacy_token(client, *DOCTOR)}"}
    doctors = (await client.get("/Hospital/Doctor/GetDoctorsInGovernorate",
                                params={"specialtie": str(refs["cardiology"].id), "index": 0}, headers=ph)).json()["doctors"]
    doc_id = next(d["id"] for d in doctors if d["email"] == DOCTOR[0])
    day = next_weekday("Wednesday")
    assert (await client.post("/Hospital/Patient/PushDateDoctor", params={"DoctorId": doc_id},
                              json={"from": "02:00 PM", "day": day.isoformat()}, headers=ph)).json() == "Save."

    booked = (await client.get("/Hospital/Doctor/BookedAppointments", headers=dh)).json()
    assert any(b["email"] == patient["email"] for b in booked)
    stats = (await client.get("/Hospital/Doctor/PatientPercentage", headers=dh)).json()
    assert stats["total"] >= 1

    assert (await client.delete("/Hospital/Doctor/CancelPatientDate", params={"PatientEmail": patient["email"]}, headers=dh)).json() is True
    notes = (await client.get("/api/Notification", headers=ph)).json()
    assert any("cancelled" in n["message"] for n in notes)


# ---------------------------------------------------------------- /api/v1


async def test_v1_full_patient_flow(client, refs):
    payload = {
        "name": "V1 Patient", "email": "v1patient@test.local", "password": "Strong@123", "phone": "01234567890",
        "birth_date": "1998-02-02", "national_id": "29802021234567", "gender": "female", "area_id": str(refs["area"].id),
    }
    reg = await client.post("/api/v1/auth/register", json=payload)
    assert reg.status_code == 201, reg.text
    weak = await client.post("/api/v1/auth/register", json=payload | {"email": "x@test.local", "password": "weak"})
    assert weak.status_code == 400

    login = await client.post("/api/v1/auth/login", json={"login": "v1patient@test.local", "password": "Strong@123"})
    assert login.status_code == 200
    h = {"Authorization": f"Bearer {login.json()['access_token']}"}
    assert (await client.get("/api/v1/users/me", headers=h)).json()["gender"] == "female"

    page = (await client.get("/api/v1/doctors", params={"specialty_id": str(refs["cardiology"].id), "sort": "rate"})).json()
    doc = next(d for d in page["items"] if d["name"] == "Ahmed Hassan")
    detail = (await client.get(f"/api/v1/doctors/{doc['id']}")).json()
    assert detail["schedule"][0]["day_name"] == "Monday"

    day = next_weekday("Tuesday")
    appt = await client.post("/api/v1/appointments", json={"doctor_id": doc["id"], "day": day.isoformat(), "time_from": "09:00 AM"}, headers=h)
    assert appt.status_code == 201, appt.text
    assert appt.json()["time_to"] == "10:00 AM"
    slots = (await client.get(f"/api/v1/doctors/{doc['id']}/booked-slots", params={"day": day.isoformat()})).json()
    assert any(s["time_from"] == "09:00 AM" for s in slots)

    moved = await client.put(f"/api/v1/appointments/{appt.json()['id']}", json={"day": day.isoformat(), "time_from": "03:00 PM"}, headers=h)
    assert moved.json()["time_from"] == "03:00 PM"

    review = await client.post(f"/api/v1/doctors/{doc['id']}/reviews", json={"rate": 4, "message": "Great"}, headers=h)
    assert review.status_code == 200, review.text
    assert (await client.get(f"/api/v1/doctors/{doc['id']}")).json()["rating_stars"] > 0

    assert (await client.delete(f"/api/v1/appointments/{appt.json()['id']}", headers=h)).status_code == 200
    assert (await client.get("/api/v1/appointments", headers=h)).json() == []


async def test_v1_password_reset(client, refs, caplog):
    import logging
    import re

    caplog.set_level(logging.INFO, logger="healthhub")
    r = await client.post("/api/v1/auth/forgot-password", json={"email": "patient@healthhub.local"})
    assert r.status_code == 200
    token = re.search(r"\n\n(\S{20,})\n\n", caplog.text).group(1)
    assert (await client.post("/api/v1/auth/reset-password", json={"token": token, "new_password": "Patient@12345"})).status_code == 200
    reuse = await client.post("/api/v1/auth/reset-password", json={"token": token, "new_password": "Patient@12345"})
    assert reuse.status_code == 400


async def test_v1_admin_guard(client):
    _ = await client.post("/api/v1/auth/login", json={"login": "patient@healthhub.local", "password": "Patient@12345"})
    h = {"Authorization": f"Bearer {_.json()['access_token']}"}
    assert (await client.get("/api/v1/admin/doctor-requests", headers=h)).status_code == 403
    admin = await client.post("/api/v1/auth/login", json={"login": "admin@healthhub.local", "password": "Admin@12345"})
    ah = {"Authorization": f"Bearer {admin.json()['access_token']}"}
    assert (await client.get("/api/v1/admin/doctor-requests", headers=ah)).status_code == 200


async def test_drug_search_and_health(client):
    assert (await client.get("/health")).json() == {"status": "ok"}
    assert (await client.get("/api/v1/health")).json() == {"status": "ok"}  # what the Android app checks
    drugs = (await client.get("/api/v1/drugs", params={"q": "parac"})).json()
    assert drugs and all("parac" in d["name"].lower() for d in drugs)
    assert any(d["name"] == "Acetaminophen" for d in (await client.get("/api/v1/drugs", params={"q": "acetamin"})).json())
