import json

import numpy as np
import pandas as pd
from typing import Optional

from pathlib import Path
from pydantic import BaseModel
from tqdm import tqdm


class Status(BaseModel):
    id: str


class Image(BaseModel):
    original: str


class GroundAndSeaCargo(BaseModel):
    kg_co2: float
    co2_in_car_km: float
    rating: int


class CarbonFootprint(BaseModel):
    ground_and_sea_cargo: GroundAndSeaCargo


class MCheck(BaseModel):
    carbon_footprint: CarbonFootprint


class Product(BaseModel):
    id: str
    status: Status
    image: Image
    m_check2: Optional[MCheck]


if __name__ == "__main__":
    path_products = Path("data\products\products\de")

    # for file_name in [path_products / "100115000000.json"]:
    for file_name in tqdm(path_products.glob("*.json")):
        with open(file_name, "r", encoding="utf-8") as f:
            jload = json.load(f)
            product = Product(**jload)
