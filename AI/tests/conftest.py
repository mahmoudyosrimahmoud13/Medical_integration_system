import os
from pathlib import Path

import pytest

os.environ["DATA_DIR"] = str(Path(__file__).parent / "fixtures")
os.environ["USE_MODEL"] = "false"

from fastapi.testclient import TestClient

from ddi_service.main import app


@pytest.fixture()
def client():
    with TestClient(app) as c:
        yield c
