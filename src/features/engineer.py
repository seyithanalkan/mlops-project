#!/usr/bin/env python3
import os
import yaml
import pandas as pd
import boto3
from urllib.parse import urlparse

def load_config():
    """
    Load configuration from CONFIG_PATH (default: config/config.yaml).
    Expects at least:
      raw_data_path:     S3 URI to raw sales.csv
      feature_data_path: S3 URI to upload features.csv
    """
    path = os.getenv("CONFIG_PATH", "config/config.yaml")
    with open(path) as f:
        return yaml.safe_load(f)

def download_s3(uri: str, local_path: str):
    """
    Download an object from S3 to a local file.
    Raises if the object is not found.
    """
    parsed = urlparse(uri)
    bucket, key = parsed.netloc, parsed.path.lstrip("/")
    os.makedirs(os.path.dirname(local_path), exist_ok=True)
    boto3.client("s3").download_file(bucket, key, local_path)
    print(f"✅ Downloaded raw data from {uri}")

def upload_s3(local_path: str, uri: str):
    """
    Upload a local file to the given S3 URI.
    """
    parsed = urlparse(uri)
    bucket, key = parsed.netloc, parsed.path.lstrip("/")
    boto3.client("s3").upload_file(local_path, bucket, key)
    print(f"⬆️ Uploaded features to {uri}")

def engineer_features(df: pd.DataFrame) -> pd.DataFrame:
    """
    Given a DataFrame with columns 'date' and 'sales',
    returns a new DataFrame with additional columns:
      - lag_1: previous day's sales
      - rolling_mean_7: expanding mean over all days up to current
    Drops the first row (lag_1=NaN) and resets the index.
    """
    df2 = df.copy()
    df2["lag_1"] = df2["sales"].shift(1)
    df2["rolling_mean_7"] = df2["sales"].expanding(min_periods=1).mean()
    return df2.iloc[1:].reset_index(drop=True)

def main():
    cfg       = load_config()
    raw_uri   = cfg["raw_data_path"]
    feat_uri  = cfg["feature_data_path"]

    # 1) Download raw sales.csv
    local_raw = "/tmp/raw.csv"
    download_s3(raw_uri, local_raw)

    # 2) Compute features
    df_raw  = pd.read_csv(local_raw, parse_dates=["date"]).sort_values("date")
    df_feat = engineer_features(df_raw)

    # 3) Write features.csv locally
    local_feat = "/tmp/features.csv"
    df_feat.to_csv(local_feat, index=False)
    print(f"🛠 Computed features, saved to {local_feat}")

    # 4) Upload features.csv to S3
    upload_s3(local_feat, feat_uri)

if __name__ == "__main__":
    main()
