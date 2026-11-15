import os
import tempfile
from datetime import date, timedelta

_tmp = tempfile.mkdtemp(prefix="healthhub-test-")
os.environ["DATABASE_URL"] = f"sqlite+aiosqlite:///{_tmp}/test.db"
os.environ["MEDIA_DIR"] = f"{_tmp}/media"
os.environ["ML_SERVICE_URL"] = ""
os.environ["REQUIRE_EMAIL_CONFIRMATION"] = "false"

import pytest  # noqa: E402
from httpx import ASGITransport, AsyncClient  # noqa: E402
from sqlalchemy import select  # noqa: E402

from app.db.base import Base  # noqa: E402
from app.db.session import SessionLocal, engine  # noqa: E402
from app.main import app  # noqa: E402
from app.models import Area, Specialty  # noqa: E402
from app.seed import ensure_default_avatar, seed_admin, seed_demo, seed_reference  # noqa: E402

PATIENT_PASSWORD = "Patient@12345"


@pytest.fixture(scope="session", autouse=True)
async def database():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    ensure_default_avatar()
    async with SessionLocal() as db:
        await seed_reference(db)
        await seed_admin(db)
        await seed_demo(db)
    yield
    await engine.dispose()


@pytest.fixture
async def client():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        yield c


@pytest.fixture
async def refs():
    """Ids the tests need: a Cairo area and the Cardiology specialty (where the demo doctor works)."""
    async with SessionLocal() as db:
        area = await db.scalar(select(Area).order_by(Area.key).limit(1))
        cardio = await db.scalar(select(Specialty).where(Specialty.name == "Cardiology"))
        return {"area": area, "cardiology": cardio}


_counter = {"n": 0}


def unique_patient() -> dict:
    _counter["n"] += 1
    n = _counter["n"]
    return {
        "name": f"Test Patient {n}",
        "email": f"patient{n}@test.local",
        "password": PATIENT_PASSWORD,
        "phone": f"0101{n:07d}",
        "birday": "1995-05-05 00:00:00.000",
        "nationalID": f"2950505{n:07d}",
        "gender": True,
    }


async def legacy_token(client, login: str, password: str) -> str:
    r = await client.post("/Auth/Login", json={"userName": login, "password": password})
    assert r.status_code == 200, r.text
    assert r.json()["token"], r.json()
    return r.json()["token"]


def next_weekday(name: str) -> date:
    days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    d = date.today() + timedelta(days=1)
    while days[d.weekday()] != name:
        d += timedelta(days=1)
    return d
