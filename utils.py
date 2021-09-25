import numpy as np
import pandas as pd


def read_clean_product_data(lang_label: str = "de") -> pd.DataFrame:
    df = pd.read_parquet(f"data\products\products\products_{lang_label}_flat.parquet")
    df["boss_thema_id"] = df["boss_thema_id"].astype("category")
    return df
