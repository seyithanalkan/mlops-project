#!/bin/bash
set -e

echo "1️⃣ Ingesting data from S3…"
python src/data/ingest.py

echo "2️⃣ Engineering features…"
python src/features/engineer.py

echo "3️⃣ Training model…"
python src/models/train.py

echo "✅ Pipeline completed successfully!"
