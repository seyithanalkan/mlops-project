import pandas as pd

from src.features.engineer import engineer_features

def test_engineer_creates_lag_and_rolling_mean(tmp_path):
    df = pd.DataFrame({"sales": [10, 20, 30, 40, 50, 60, 70, 80]})
    df_out = engineer_features(df)

    # lag_1 should be [10,20,...,70]
    expected_lags = [pd.NA, 10, 20, 30, 40, 50, 60, 70]
    assert df_out["lag_1"].tolist() == expected_lags[1:]

    # rolling_mean_7 at each point (with min_periods=1) is:
    # [10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0, 45.0]
    expected_rm_7 = [10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0, 45.0]
    # after dropping the first row, compare indices 1–7:
    assert df_out["rolling_mean_7"].round(1).tolist() == expected_rm_7[1:]
