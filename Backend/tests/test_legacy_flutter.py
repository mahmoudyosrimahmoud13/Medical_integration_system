"""The exact calls the 2024 Flutter app (flutter_final branch) makes, with its exact payloads."""

import json

from tests.conftest import legacy_token, next_weekday, unique_patient


async def register_legacy(client, area_key: str) -> dict:
    data = unique_patient() | {"area": area_key}
    r = await client.post("/Auth/Register", data={"input": json.dumps(data)})
    assert r.status_code == 200, r.text
    assert r.json()["error"] is False, r.json()
    return data


async def test_address_and_specialties(client):
    govs = (await client.get("/Adress/GetGovernorate")).json()
    assert {"id", "key"} <= govs[0].keys()
    cairo = next(g for g in govs if g["key"] == "Cairo")
    areas = (await client.get("/Adress/GetAreas", params={"GovermentKey": "Cairo"})).json()
    assert areas and {"id", "key"} <= areas[0].keys()
    assert (await client.get("/Adress/GetAreas", params={"GovermentKey": cairo["id"]})).json() == areas
    specs = (await client.get("/Hospital/Specialties")).json()
    assert len(specs) >= 42 and {"id", "name"} <= specs[0].keys()


async def test_register_login_getuser(client, refs):
    data = await register_legacy(client, refs["area"].key)

    # duplicate email is reported the old way: HTTP 200 + error flag
    again = await client.post("/Auth/Register", data={"input": json.dumps(data)})
    assert again.json() == again.json() | {"error": True, "message": "The Email Is Registered"}

    r = await client.post("/Auth/Login", json={"userName": data["email"], "password": data["password"]})
    body = r.json()
    assert body["message"] is None and body["token"] and body["area"] == refs["area"].key and body["gove"]
    assert body["imgSrc"].endswith("/Image/User/default.png")

    bad = (await client.post("/Auth/Login", json={"userName": data["email"], "password": "Wrong@12345"})).json()
    assert bad["token"] is None and bad["message"] == "Email Or Password Incorrect"

    me = await client.get("/Auth/GetUser", params={"data": data["email"]}, headers={"Authorization": f"Bearer {body['token']}"})
    assert me.json()["name"] == data["name"] and me.json()["gender"] == "Male"


async def test_register_with_image(client, refs):
    data = unique_patient() | {"area": refs["area"].key}
    png = (await client.get("/Image/User/default.png")).content
    r = await client.post("/Auth/Register", data={"input": json.dumps(data)}, files={"img": ("/data/user/0/photo.png", png, "image/png")})
    assert r.json()["error"] is False
    login = (await client.post("/Auth/Login", json={"userName": data["email"], "password": data["password"]})).json()
    assert not login["imgSrc"].endswith("default.png")
    assert (await client.get(login["imgSrc"].replace("http://test", ""))).status_code == 200


async def test_search_details_book_list_cancel(client, refs):
    data = await register_legacy(client, refs["area"].key)
    token = await legacy_token(client, data["email"], data["password"])
    h = {"Authorization": f"Bearer {token}"}

    # Flutter sends area/goveId as null and these exact flags
    found = await client.get(
        "/Hospital/Doctor/GetDoctorsInGovernorate",
        params={"specialtie": str(refs["cardiology"].id), "rate": "true", "joinDate": "true", "index": "0"},
        headers=h,
    )
    assert found.status_code == 200, found.text
    doctors = found.json()["doctors"]
    assert found.json()["count"] >= 1
    doc = next(d for d in doctors if d["email"] == "doctor@healthhub.local")
    assert {"id", "area", "drImg", "name", "phone", "addressDescrption", "rate"} <= doc.keys()

    by_name = await client.get(
        "/Hospital/Doctor/SerchDoctorsWithName",
        params={"DoctorName": "Ahmed", "specialtie": str(refs["cardiology"].id), "index": "0"},
        headers=h,
    )
    assert by_name.json()["count"] >= 1

    detail = (await client.get("/Hospital/Doctor/GetDoctor", params={"Id": doc["id"]})).json()
    assert detail["departmentName"] == "Cardiology" and detail["collegeName"] and len(detail["dates"]) == 6

    # the demo data books some of the doctor's hours, so take the first free one
    day = next_weekday("Monday")
    slot = None
    for hour in ["09:00 AM", "10:00 AM", "11:00 AM", "12:00 PM", "01:00 PM", "02:00 PM", "03:00 PM", "04:00 PM"]:
        booked = await client.post(
            "/Hospital/Patient/PushDateDoctor", params={"DoctorId": doc["id"]},
            json={"from": hour, "day": f"{day.isoformat()}T00:00:00.000"}, headers=h,
        )
        if booked.json() == "Save.":
            slot = hour
            break
        assert booked.json() == "this date was Previously Selected", booked.text
    assert slot, "no free hour found on Monday"

    # same doctor again -> rejected
    again = await client.post(
        "/Hospital/Patient/PushDateDoctor", params={"DoctorId": doc["id"]},
        json={"from": "11:00 AM", "day": day.isoformat()}, headers=h,
    )
    assert "upcoming appointment" in again.json()

    # a day the doctor doesn't work (Friday)
    other = await register_legacy(client, refs["area"].key)
    h2 = {"Authorization": f"Bearer {await legacy_token(client, other['email'], other['password'])}"}
    friday = await client.post(
        "/Hospital/Patient/PushDateDoctor", params={"DoctorId": doc["id"]},
        json={"from": "10:00 AM", "day": next_weekday("Friday").isoformat()}, headers=h2,
    )
    assert friday.json() == "Choose The Appropriate Day"
    # slot already taken by the first patient
    taken = await client.post(
        "/Hospital/Patient/PushDateDoctor", params={"DoctorId": doc["id"]},
        json={"from": slot.replace(":00", ":30"), "day": day.isoformat()}, headers=h2,
    )
    assert taken.json() == "this date was Previously Selected"
    # outside working hours
    late = await client.post(
        "/Hospital/Patient/PushDateDoctor", params={"DoctorId": doc["id"]},
        json={"from": "08:00 PM", "day": day.isoformat()}, headers=h2,
    )
    assert late.json() == "Choose The Appropriate Time"

    dates = (await client.get("/Hospital/Patient/GetPatientDates", headers=h)).json()
    assert len(dates) == 1
    d = dates[0]
    hours = ["09:00 AM", "10:00 AM", "11:00 AM", "12:00 PM", "01:00 PM", "02:00 PM", "03:00 PM", "04:00 PM", "05:00 PM"]
    assert d["from"] == slot and d["to"] == hours[hours.index(slot) + 1] and d["dayName"] == "Monday"
    assert {"paientDateId", "doctorName", "doctorSpecialty", "areaName", "governorateName", "date"} <= d.keys()

    cancelled = await client.delete("/Hospital/Patient/CancelBookedDate", params={"PaintDateid": d["paientDateId"]}, headers=h)
    assert cancelled.json() is True
    assert (await client.get("/Hospital/Patient/GetPatientDates", headers=h)).json() == []


async def test_auth_required(client):
    r = await client.get("/Hospital/Patient/GetPatientDates")
    assert r.status_code == 401


async def test_forget_password_post(client):
    r = await client.post("/Auth/ForgetPassword", json={"email": "nobody@test.local"})
    assert r.status_code == 200
