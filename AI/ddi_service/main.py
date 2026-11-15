"""HealthHub drug interaction service.

1. Look the pair up in DrugBank's list of known interactions. This is the reliable answer
   and comes with a plain description ("Aspirin may increase the anticoagulant activities of Warfarin.").
2. Only for pairs DrugBank does not list, and only when USE_MODEL=true, ask the MVN-DDI model.
   It may only say "possible interaction" and never names a type (its type labels were lost).

POST /v1/check          new API, takes DrugBank ids and/or SMILES
POST /CheckInteraction  the 2024 Flask contract, kept so old clients keep working
GET  /health
"""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from ddi_service.config import settings
from ddi_service.known import KnownInteractions

log = logging.getLogger("ddi")

state: dict = {"known": None, "model": None, "model_error": None}


def load_model():
    if not settings.use_model:
        return None
    try:
        from ddi_service.mvn import (
            Predictor,  # needs torch, only imported when asked for
        )
        return Predictor(str(settings.model_weights))
    except Exception as exc:
        state["model_error"] = str(exc)
        log.exception("Could not load the MVN-DDI model; continuing with DrugBank only")
        return None


@asynccontextmanager
async def lifespan(_: FastAPI):
    state["known"] = KnownInteractions(settings.data_dir)
    if not state["known"].loaded:
        log.warning("No DrugBank data in %s. Run: ./run.sh data", settings.data_dir)
    state["model"] = load_model()
    yield


app = FastAPI(title="HealthHub drug interactions", version="2.0.0", lifespan=lifespan)


class CheckIn(BaseModel):
    drug_1_id: str | None = Field(None, examples=["DB00945"])
    drug_2_id: str | None = Field(None, examples=["DB00682"])
    drug_1_smiles: str | None = None
    drug_2_smiles: str | None = None
    drug_1_name: str | None = Field(None, examples=["Aspirin"])
    drug_2_name: str | None = Field(None, examples=["Warfarin"])


class CheckOut(BaseModel):
    interacts: bool
    source: str  # "drugbank" | "model" | "none"
    description: str
    type: int | None = None          # DrugBank interaction type (row of interaction_types.csv)
    confidence: float | None = None  # model score, only when source == "model"


def check(body: CheckIn) -> CheckOut:
    known: KnownInteractions = state["known"]
    id1 = body.drug_1_id or (known.smiles_to_id.get(body.drug_1_smiles.strip()) if body.drug_1_smiles else None)
    id2 = body.drug_2_id or (known.smiles_to_id.get(body.drug_2_smiles.strip()) if body.drug_2_smiles else None)
    if not (id1 or body.drug_1_smiles) or not (id2 or body.drug_2_smiles):
        raise HTTPException(422, "Send a DrugBank id or a SMILES for both drugs")

    names = {k: v for k, v in ((id1, body.drug_1_name), (id2, body.drug_2_name)) if k and v}
    if id1 and id2:
        hit = known.find(id1, id2)
        if hit:
            return CheckOut(interacts=True, source="drugbank", description=hit.describe(names), type=hit.type)

    model = state["model"]
    s1 = body.drug_1_smiles or known.id_to_smiles.get(id1 or "")
    s2 = body.drug_2_smiles or known.id_to_smiles.get(id2 or "")
    if model is not None and s1 and s2:
        try:
            score = model.max_score(s1, s2)
        except ValueError:
            score = None
        if score is not None and score >= settings.model_threshold:
            a, b = body.drug_1_name or "these drugs", body.drug_2_name or ""
            pair = f"{a} and {b}" if b else a
            return CheckOut(
                interacts=True, source="model", confidence=round(score, 3),
                description=f"Possible interaction between {pair}. It is not in DrugBank's list; this is a model estimate, so check with a pharmacist.",
            )
    return CheckOut(interacts=False, source="none", description="No known interaction")


@app.post("/v1/check", response_model=CheckOut)
def check_v1(body: CheckIn) -> CheckOut:
    return check(body)


class LegacyIn(BaseModel):
    drug_1: str
    drug_2: str


@app.post("/CheckInteraction")
def check_legacy(body: LegacyIn) -> dict:
    out = check(CheckIn(drug_1_smiles=body.drug_1, drug_2_smiles=body.drug_2))
    return {
        "InteractionResult": out.interacts,
        "InteractionNameIndex": out.type if out.type is not None else -1,
        "Description": out.description,
        "Source": out.source,
    }


@app.get("/health")
def health() -> dict:
    known: KnownInteractions = state["known"]
    return {
        "status": "ok",
        "known_pairs": len(known) if known else 0,
        "model_loaded": state["model"] is not None,
        "model_error": state["model_error"],
        "model_threshold": settings.model_threshold,
    }
