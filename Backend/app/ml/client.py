"""Client for the drug interaction service in AI/ (ddi_service).

    POST {ML_SERVICE_URL}/v1/check
        {"drug_1_id", "drug_2_id", "drug_1_smiles", "drug_2_smiles", "drug_1_name", "drug_2_name"}
    ->  {"interacts": bool, "source": "drugbank" | "model" | "none", "description": str, "type": int | null}

If the service only speaks the 2024 Flask contract (POST /CheckInteraction with SMILES), that is used instead.

Results are cached per drug pair in the drug_interactions table, so each pair hits the model once.
When ML_SERVICE_URL is empty, or the service is down, check_pair returns None ("unknown").
"""

import logging

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models import Drug, DrugInteraction

log = logging.getLogger("healthhub.ml")


def describe(row: DrugInteraction) -> str:
    if not row.interacts:
        return "No interaction found"
    if row.reason:
        return row.reason
    return f"Interaction type #{row.interaction_type}"


async def check_pair(db: AsyncSession, a: Drug, b: Drug) -> DrugInteraction | None:
    first, second = sorted([a, b], key=lambda d: d.id)
    cached = await db.scalar(
        select(DrugInteraction).where(DrugInteraction.drug_a_id == first.id, DrugInteraction.drug_b_id == second.id)
    )
    if cached is not None:
        return cached
    if not settings.ml_service_url:
        return None
    base = settings.ml_service_url.rstrip("/")
    try:
        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.post(
                base + "/v1/check",
                json={
                    "drug_1_id": first.id, "drug_2_id": second.id,
                    "drug_1_smiles": first.smiles, "drug_2_smiles": second.smiles,
                    "drug_1_name": first.name, "drug_2_name": second.name,
                },
            )
            if resp.status_code == 404:  # old Flask service
                resp = await client.post(base + "/CheckInteraction", json={"drug_1": first.smiles, "drug_2": second.smiles})
            resp.raise_for_status()
            data = {k.lower(): v for k, v in resp.json().items()}
    except Exception:  # noqa: BLE001
        log.exception("ML service call failed")
        return None
    if "interacts" in data:
        row = DrugInteraction(
            drug_a_id=first.id, drug_b_id=second.id, interacts=bool(data["interacts"]),
            interaction_type=data.get("type") if data.get("type") is not None else -1,
            reason=data.get("description") or None,
        )
    else:
        row = DrugInteraction(
            drug_a_id=first.id, drug_b_id=second.id, interacts=bool(data.get("interactionresult")),
            interaction_type=int(data.get("interactionnameindex", -1)), reason=data.get("description") or None,
        )
    db.add(row)
    await db.commit()
    return row
