from typing import Any, Dict, Union
import numpy as np
import pandas as pd

import abc
from dataclasses import dataclass


class RecommenderError(Exception):
    pass


@dataclass
class BaseRecommender(abc.ABC):
    col_product_id: str = "id"
    _fitted: bool = False

    @abc.abstractmethod
    def fit(self, X: pd.DataFrame) -> None:
        ...

    def predict(self, X: pd.DataFrame) -> pd.Series:
        if not self._fitted:
            raise RecommenderError("The recommender must be trained first.")

        preds = self._predict(X)
        return preds

    @abc.abstractmethod
    def _predict(self, X: pd.DataFrame) -> pd.Series:
        ...

    def predict_single_instance(self, x: Dict[str, Union[str, int, float]]) -> str:
        X = pd.DataFrame.from_records([x])
        pred = self.predict(X)
        return pred.iloc[0]


@dataclass
class BasicBossThemaRecommender(BaseRecommender):
    col_group: str = "boss_thema_id"

    def fit(self, X: pd.DataFrame) -> None:
        self.groups = (
            X.groupby(self.col_group)[self.col_product_id]
            .apply(list)
            .rename("__preds__")
        )

        self._fitted = True

    def _predict(self, X: pd.DataFrame) -> pd.Series:
        if self.col_group not in X:
            raise RecommenderError(f"the required column is missing: {self.col_group}")
        df_with_preds = X.merge(
            self.groups, left_on=self.col_group, right_index=True, validate="m:1"
        )
        preds = df_with_preds.set_index(self.col_product_id)["__preds__"]
        return preds


class BaseSelector(abc.ABC):
    col_product_id: str = "id"

    @abc.abstractmethod
    def select(self, X: pd.Series) -> pd.Series:
        ...


@dataclass
class TopOneSelector(BaseSelector):
    col_target = "carbon_footprint_co2_in_car_km"

    def select(self, X: pd.Series, product_data: pd.DataFrame) -> pd.DataFrame:
        col_preds = "recommendation_id"
        X_ = X.copy()
        # expand lists into multiple rows
        stacked_preds = (
            X_.apply(pd.Series)
            .stack()
            .reset_index()
            .rename(columns={0: col_preds})[[self.col_product_id, col_preds]]
        )
        # add targets for the tested products
        col_target_test = f"{self.col_target}_test"
        product_scores = product_data[[self.col_product_id, self.col_target]].rename(
            columns={self.col_target: col_target_test}
        )
        stacked_preds = stacked_preds.merge(
            product_scores,
            left_on=self.col_product_id,
            right_on=self.col_product_id,
        )
        # add targets for the recommendations
        col_target_reco = f"{self.col_target}_reco"
        product_scores = product_data[[self.col_product_id, self.col_target]].rename(
            columns={self.col_target: col_target_reco, self.col_product_id: col_preds}
        )
        stacked_preds = stacked_preds.merge(
            product_scores,
            left_on=col_preds,
            right_on=col_preds,
        )
        # choose the product that is the best
        col_diff = "diff_preds"
        stacked_preds[col_diff] = (
            stacked_preds[col_target_test] - stacked_preds[col_target_reco]
        )
        idx_best_options = stacked_preds.groupby(self.col_product_id)[col_diff].idxmax()
        # drop entries with missing bestalternative
        best_options = stacked_preds.loc[idx_best_options.loc[lambda x: x.notnull()]]
        # drop entries with the best alternative having the same metric value
        best_options = best_options[best_options[col_diff] > 0]

        # format the output
        best_options = best_options[
            [self.col_product_id, col_preds, col_diff]
        ].reset_index(drop=True)

        return best_options
