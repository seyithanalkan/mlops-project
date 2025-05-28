#!/usr/bin/env python3

import os
import yaml
import pandas as pd
import pickle
from urllib.parse import urlparse
import boto3
from sklearn.preprocessing import MinMaxScaler
from tensorflow.keras.callbacks import EarlyStopping
from tensorflow.keras.layers import LSTM, Dense
from tensorflow.keras.models import Sequential

def load_config():
    path = os.getenv("CONFIG_PATH", "config/config.yaml")
    with open(path) as f:
        return yaml.safe_load(f)

def _download_s3_to_local(s3_uri: str, local_tmp: str) -> str:
    """Download a file from S3 URI to a local path."""
    parsed = urlparse(s3_uri)
    bucket = parsed.netloc
    key = parsed.path.lstrip("/")
    os.makedirs(os.path.dirname(local_tmp), exist_ok=True)
    boto3.client("s3").download_file(bucket, key, local_tmp)
    return local_tmp

def _upload_local_to_s3(local_path: str, s3_uri: str) -> None:
    """Upload a local file to the given S3 URI."""
    parsed = urlparse(s3_uri)
    bucket = parsed.netloc
    key = parsed.path.lstrip("/")
    boto3.client("s3").upload_file(local_path, bucket, key)

def train_and_deploy():
    """Train & Deploy & Restart Api"""
    cfg            = load_config()
    feat_uri       = cfg["feature_data_path"]
    model_uri      = cfg["model_path"]
    scaler_X_path  = cfg.get("scaler_X_path", model_uri.replace(".h5", "_scaler_X.pkl"))
    scaler_y_path  = cfg.get("scaler_y_path", model_uri.replace(".h5", "_scaler_y.pkl"))

    local_feat = "/tmp/features.csv"
    if feat_uri.startswith("s3://"):
        _download_s3_to_local(feat_uri, local_feat)
    else:
        local_feat = feat_uri

    df = pd.read_csv(local_feat, parse_dates=["date"])
    df.sort_values("date", inplace=True)

    X_raw = df[["lag_1", "rolling_mean_7"]].values
    y_raw = df[["sales"]].values.reshape(-1, 1)

    scaler_X = MinMaxScaler()
    scaler_y = MinMaxScaler()
    X_scaled_2d = scaler_X.fit_transform(X_raw)
    y_scaled     = scaler_y.fit_transform(y_raw)

    X_scaled = X_scaled_2d.reshape(len(df), 1, 2)

    model = Sequential([
        LSTM(32, input_shape=(1, 2)),
        Dense(1)
    ])
    model.compile(optimizer="adam", loss="mse")
    es = EarlyStopping(monitor="loss", patience=5, restore_best_weights=True)
    model.fit(X_scaled, y_scaled, epochs=50, batch_size=16, callbacks=[es], verbose=2)

    local_model     = "/tmp/model.h5"
    os.makedirs(os.path.dirname(local_model), exist_ok=True)
    model.save(local_model)

    local_scaler_X = "/tmp/scaler_X.pkl"
    local_scaler_y = "/tmp/scaler_y.pkl"
    with open(local_scaler_X, "wb") as f:
        pickle.dump(scaler_X, f)
    with open(local_scaler_y, "wb") as f:
        pickle.dump(scaler_y, f)

    if model_uri.startswith("s3://"):
        _upload_local_to_s3(local_model, model_uri)
        _upload_local_to_s3(local_scaler_X, scaler_X_path)
        _upload_local_to_s3(local_scaler_y, scaler_y_path)
    else:
        os.replace(local_model, model_uri)
        os.replace(local_scaler_X, scaler_X_path)
        os.replace(local_scaler_y, scaler_y_path)

    ecs_cluster = os.getenv("ECS_CLUSTER")
    ecs_service = os.getenv("ECS_SERVICE")
    if ecs_cluster and ecs_service:
        ecs = boto3.client("ecs")
        print(f"🔄 Forcing new deployment on {ecs_cluster}/{ecs_service}…")
        ecs.update_service(
            cluster=ecs_cluster,
            service=ecs_service,
            forceNewDeployment=True
        )
        print("✅ ECS service rolled out new task definition.")
    else:
        print("⚠️ ECS_CLUSTER or ECS_SERVICE not set; skipping ECS update.")

if __name__ == "__main__":
    train_and_deploy()
