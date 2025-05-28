#!/usr/bin/env python3
import os
import yaml
import pandas as pd
import boto3
from urllib.parse import urlparse


def load_config() -> dict:
    """Load pipeline configuration from CONFIG_PATH or default."""
    path = os.getenv("CONFIG_PATH", "config/config.yaml")
    with open(path) as f:
        return yaml.safe_load(f)


def _download_s3_to_local(s3_uri: str, local_tmp: str) -> str:
    """Download an s3:// URI to a local path."""
    parsed = urlparse(s3_uri)
    boto3.client("s3").download_file(parsed.netloc, parsed.path.lstrip("/"), local_tmp)
    return local_tmp


def _upload_local_to_s3(local_path: str, s3_uri: str):
    """Upload a local file to an s3:// URI."""
    parsed = urlparse(s3_uri)
    boto3.client("s3").upload_file(local_path, parsed.netloc, parsed.path.lstrip("/"))


def ingest() -> tuple[pd.DataFrame, dict]:
    """
    1) Load config
    2) Read raw_data_path (local or s3://)
    3) Drop any rows with missing values
    4) Write cleaned data to processed_data_path (local or s3://)
    5) Return cleaned DataFrame and config dict
    """
    cfg = load_config()
    raw_uri = cfg["raw_data_path"]
    proc_uri = cfg["processed_data_path"]

    if raw_uri.startswith("s3://"):
        local_raw = "/tmp/raw.csv"
        _download_s3_to_local(raw_uri, local_raw)
    else:
        local_raw = raw_uri

    df = pd.read_csv(local_raw)
    df_clean = df.dropna()

    local_proc = "/tmp/processed.csv"
    df_clean.to_csv(local_proc, index=False)
    if proc_uri.startswith("s3://"):
        _upload_local_to_s3(local_proc, proc_uri)
    else:
        os.replace(local_proc, proc_uri)

    return df_clean, cfg
