"""Settings, read from environment variables (or a .env file)."""

from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

ROOT = Path(__file__).resolve().parent.parent


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore", protected_namespaces=())

    data_dir: Path = ROOT / "data"
    # The MVN-DDI model is optional. It needs requirements-model.txt (about 3 GB with PyTorch).
    use_model: bool = False
    model_weights: Path = ROOT / "weights" / "mvn_ddi.pt"
    # Only call it an interaction when the model is this sure. At 0.95 it catches about 4 in 10
    # real interactions and wrongly flags about 1 in 20 safe pairs (see PLAN.md).
    model_threshold: float = 0.95


settings = Settings()
