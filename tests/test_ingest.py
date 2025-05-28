# tests/test_ingest.py

import pandas as pd
import yaml

from src.data.ingest import ingest


def test_ingest_creates_file(tmp_path, monkeypatch):
    sample_csv = tmp_path / "sales.csv"
    df_sample = pd.DataFrame(
        {"A": [1, 2, None], "B": ["x", "y", "z"]}
    )
    df_sample.to_csv(sample_csv, index=False)

    cfg = {
        "raw_data_path": str(sample_csv),
        "processed_data_path": str(tmp_path / "sales_processed.csv"),
    }
    config_file = tmp_path / "config.yaml"
    with open(config_file, "w") as f:
        yaml.safe_dump(cfg, f)

    monkeypatch.setenv("CONFIG_PATH", str(config_file))
    df_clean, _ = ingest()

    assert df_clean.shape[0] == 2
    assert (tmp_path / "sales_processed.csv").exists()
