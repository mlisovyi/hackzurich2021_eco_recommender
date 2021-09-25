# %%
import numpy as np
import pandas as pd
from pathlib import Path

from utils import read_clean_product_data
from r_eco_mmender import BasicBossThemaRecommender, TopOneSelector

# %%
if __name__ == "__main__":
    # %%
    df = read_clean_product_data()

    # %%
    mdl = BasicBossThemaRecommender()
    mdl.fit(df)

    # %%
    X_test = df
    all_recommendations = mdl.predict(X_test)

    # %%
    selector = TopOneSelector()
    best_recommendations = selector.select(all_recommendations, df)
    # print(best_recommendations)

    best_recommendations.to_csv(Path("data/recommendations.csv"), index=False)
# %%
