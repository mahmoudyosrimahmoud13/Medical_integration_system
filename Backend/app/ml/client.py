"""Client for the drug interaction model (the old Flask service from the `flask` branch).

Contract (unchanged from 2024):
    POST {ML_SERVICE_URL}/CheckInteraction  {"drug_1": "<smiles>", "drug_2": "<smiles>"}
    ->  {"InteractionResult": bool, "InteractionNameIndex": int}   (-1 = no interaction)

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
    try:
        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.post(
                settings.ml_service_url.rstrip("/") + "/CheckInteraction",
                json={"drug_1": first.smiles, "drug_2": second.smiles},
            )
            resp.raise_for_status()
            data = {k.lower(): v for k, v in resp.json().items()}
    except Exception:  # noqa: BLE001
        log.exception("ML service call failed")
        return None
    row = DrugInteraction(
        drug_a_id=first.id,
        drug_b_id=second.id,
        interacts=bool(data.get("interactionresult")),
        interaction_type=int(data.get("interactionnameindex", -1)),
    )
    db.add(row)
    await db.commit()
    return row
