#!/usr/bin/env python3
"""
generate_data.py
Create a dummy daily sales CSV for testing.
"""
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import os

def main():
    print("[Stage 1] Starting data generation process...")
    days = 180
    start = datetime.today() - timedelta(days=days)
    dates = [start + timedelta(days=i) for i in range(days)]

    sales = (np.random.rand(days) * 400 + 100).round().astype(int)

    df = pd.DataFrame({'date': dates, 'sales': sales})
    os.makedirs('data/raw', exist_ok=True)
    out_path = 'data/raw/sales.csv'
    df.to_csv(out_path, index=False)
    print(f"Generated {len(df)} rows of dummy data at {out_path}")

if __name__ == "__main__":
    main()
