#!/usr/bin/env python3

import os
import sys
import time
import logging
import pickle
from datetime import datetime
from typing import Any, Dict, List, Optional, Union
from urllib.parse import urlparse
import boto3
from botocore.exceptions import NoCredentialsError
import numpy as np
from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, validator
from tensorflow.keras.models import load_model

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
if project_root not in sys.path:
    sys.path.insert(0, project_root)
from src.data.ingest import load_config


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger("retail-forecast-api")


class IdentityScaler:
    """A scaler that returns inputs unchanged."""
    def transform(self, x: np.ndarray) -> np.ndarray:
        return x
    def inverse_transform(self, x: np.ndarray) -> np.ndarray:
        return x

class DummyModel:
    """A fallback model that always predicts zero."""
    def predict(self, x: np.ndarray) -> np.ndarray:
        return np.zeros((x.shape[0], 1))
    @property
    def name(self) -> str:
        return "dummy"
    @property
    def version(self) -> str:
        return "0.0.0"
    @property
    def features(self) -> List[str]:
        return ["lag_1", "rolling_mean_7"]
    @property
    def trained_date(self) -> Optional[str]:
        return None

def download_s3(uri: str, local_path: str) -> str:
    """Download a file from S3 URI to a local path."""
    parsed = urlparse(uri)
    bucket = parsed.netloc
    key = parsed.path.lstrip("/")
    os.makedirs(os.path.dirname(local_path), exist_ok=True)
    boto3.client("s3").download_file(bucket, key, local_path)
    logger.info(f"Downloaded S3 file from {uri}")
    return local_path

def get_model_and_scalers() -> tuple:
    """
    Load model and scalers independently.
    - On any model load failure, use DummyModel.
    - On any scaler load failure, use IdentityScaler.
    """
    cfg = load_config()
    model_uri = cfg.get("model_path", "models/lstm_model.h5")
    # ── MODEL LOADING ──
    try:
        local_model = "/tmp/model.h5"
        if model_uri.startswith("s3://"):
            download_s3(model_uri, local_model)
        else:
            local_model = model_uri
        model = load_model(local_model, compile=False)
        # Attach metadata if available
        model.name = cfg.get("model_name", getattr(model, "name", "lstm_model"))
        model.version = cfg.get("model_version", getattr(model, "version", "0.1.0"))
        model.features = cfg.get("model_features", ["lag_1", "rolling_mean_7"])
        model.trained_date = cfg.get("trained_date", datetime.now().isoformat())
        logger.info("Successfully loaded LSTM model.")
    except (NoCredentialsError, Exception) as e:
        logger.warning(f"Model load failed ({e}); using DummyModel.")
        model = DummyModel()


    default_sx = model_uri.replace(".h5", "_scaler_X.pkl")
    default_sy = model_uri.replace(".h5", "_scaler_y.pkl")
    scaler_X_uri = cfg.get("scaler_X_path", default_sx)
    scaler_y_uri = cfg.get("scaler_y_path", default_sy)

    try:
        local_sx = "/tmp/scaler_X.pkl"
        local_sy = "/tmp/scaler_y.pkl"
        if scaler_X_uri.startswith("s3://"):
            download_s3(scaler_X_uri, local_sx)
        else:
            local_sx = scaler_X_uri
        if scaler_y_uri.startswith("s3://"):
            download_s3(scaler_y_uri, local_sy)
        else:
            local_sy = scaler_y_uri

        scaler_X = pickle.load(open(local_sx, "rb"))
        scaler_y = pickle.load(open(local_sy, "rb"))
        logger.info("Successfully loaded MinMaxScalers.")
    except (NoCredentialsError, Exception) as e:
        logger.warning(f"Scaler load failed ({e}); using IdentityScaler.")
        scaler_X = IdentityScaler()
        scaler_y = IdentityScaler()

    return model, scaler_X, scaler_y


app = FastAPI(
    title="Retail Forecast Serve",
    version="0.1",
    description="API for retail sales forecasting"
)


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.state.model, app.state.scaler_X, app.state.scaler_y = get_model_and_scalers()
app.state.request_count = 0
app.state.start_time = time.time()


@app.middleware("http")
async def add_process_time_header(request: Request, call_next) -> Response:
    start = time.time()
    app.state.request_count += 1
    request_id = f"{int(start * 1000)}-{app.state.request_count}"
    request.state.request_id = request_id
    logger.info(f"Request {request_id}: {request.method} {request.url.path}")
    response = await call_next(request)
    proc_time = time.time() - start
    response.headers["X-Process-Time"] = str(proc_time)
    response.headers["X-Request-ID"] = request_id
    logger.info(f"Response {request_id}: status={response.status_code}, time={proc_time:.4f}s")
    return response


@app.get("/health")
def health() -> Dict[str, Any]:
    uptime = time.time() - app.state.start_time
    return {"status": "ok", "timestamp": datetime.now().isoformat(), "uptime_seconds": int(uptime)}


@app.get("/metrics")
def metrics() -> Dict[str, Any]:
    uptime = time.time() - app.state.start_time
    return {
        "uptime_seconds": int(uptime),
        "request_count": app.state.request_count,
        "requests_per_second": app.state.request_count / uptime if uptime > 0 else 0,
        "timestamp": datetime.now().isoformat(),
    }


class ModelMetadataResponse(BaseModel):
    name: str
    version: str
    features: List[str]
    trained_date: Optional[str] = None

@app.get("/model", response_model=ModelMetadataResponse)
def model_metadata() -> ModelMetadataResponse:
    m = app.state.model
    return ModelMetadataResponse(
        name=m.name,
        version=m.version,
        features=m.features,
        trained_date=m.trained_date,
    )


class PredictRequest(BaseModel):
    lag_1: float = Field(..., description="Previous day's sales")
    rolling_mean_7: float = Field(..., description="7-day rolling average")
    @validator("lag_1", "rolling_mean_7")
    def nonneg(cls, v):
        if v < 0: raise ValueError("Must be non-negative")
        return v

class PredictionResponse(BaseModel):
    prediction: float
    request_id: str
    timestamp: str
    processing_time: float

@app.post("/predict", response_model=PredictionResponse)
def predict(req: PredictRequest, request: Request) -> PredictionResponse:
    try:

        x_raw = np.array([[req.lag_1, req.rolling_mean_7]])
        x_scaled = app.state.scaler_X.transform(x_raw).reshape((1, 1, 2))


        start = datetime.now().timestamp()
        y_scaled = app.state.model.predict(x_scaled)
        proc_time = datetime.now().timestamp() - start


        pred = float(app.state.scaler_y.inverse_transform(y_scaled)[0, 0])

        return PredictionResponse(
            prediction=pred,
            request_id=request.state.request_id,
            timestamp=datetime.now().isoformat(),
            processing_time=proc_time,
        )
    except Exception as e:
        logger.error(f"Prediction error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


