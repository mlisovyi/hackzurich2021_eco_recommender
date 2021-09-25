import json

import numpy as np
import pandas as pd
from typing import Optional

from pathlib import Path
from pydantic import BaseModel, validator
from tqdm import tqdm
import re


class Status(BaseModel):
    id: str


class Image(BaseModel):
    original: str


class AirGroundAndSeaCargo(BaseModel):
    kg_co2: float
    co2_in_car_km: float
    rating: int


class CarbonFootprint(BaseModel):
    ground_and_sea_cargo: Optional[AirGroundAndSeaCargo]
    air_cargo: Optional[AirGroundAndSeaCargo]

    @validator("air_cargo")
    def check_air_or_groundandsea(cls, v, values):
        if "a" in values and v:
            raise ValueError("both air and ground and sea can not be given")
        return v


class AnimalWelfare(BaseModel):
    rating: int


class MCheck(BaseModel):
    carbon_footprint: Optional[CarbonFootprint]
    animal_welfare: Optional[AnimalWelfare]


class Product(BaseModel):
    id: str
    name: str
    regulated_description: Optional[str]
    status: Status
    image: Image
    m_check2: Optional[MCheck]

    @validator("regulated_description")
    def check_for_ch_and_d_descriptions(cls, v: str):
        if v.startswith("$CH:"):
            v_out = re.findall(r"\$(DE|D): (.*?)\$", v)[0][1]
        elif v.startswith("CH:"):
            v_out = re.findall(r"(DE|D): (.*?)", v)[0][1]
        else:
            v_out = v
        return v_out


if __name__ == "__main__":
    path_products = Path("data\products\products\de")

    records = []
    for file_name in tqdm(list(path_products.glob("*.json"))):
        with open(file_name, "r", encoding="utf-8") as f:
            jload = json.load(f)
        product = Product(**jload)

        if product.status.id != "available":
            continue

        record = {
            "id": product.id,
            "name": product.name,
            "regulated_description": product.regulated_description,
            "image": product.image.original,
        }

        # try to get animal welfare, if available
        try:
            record["animal_welfare_rating"] = product.m_check2.animal_welfare.rating
        except AttributeError:
            pass

        # try to get carbon_footprint of ground_and_sea_cargo, if available
        try:
            record[
                "carbon_footprint_rating"
            ] = product.m_check2.carbon_footprint.ground_and_sea_cargo.rating
            record[
                "carbon_footprint_kg_co2"
            ] = product.m_check2.carbon_footprint.ground_and_sea_cargo.kg_co2
            record[
                "carbon_footprint_co2_in_car_km"
            ] = product.m_check2.carbon_footprint.ground_and_sea_cargo.co2_in_car_km
        except AttributeError:
            pass

        # try to get carbon_footprint of air_cargo, if available
        try:
            record[
                "carbon_footprint_rating"
            ] = product.m_check2.carbon_footprint.air_cargo.rating
            record[
                "carbon_footprint_kg_co2"
            ] = product.m_check2.carbon_footprint.air_cargo.kg_co2
            record[
                "carbon_footprint_co2_in_car_km"
            ] = product.m_check2.carbon_footprint.air_cargo.co2_in_car_km
        except AttributeError:
            pass

        records.append(record)
    df = pd.DataFrame.from_records(records)

    fname_csv = path_products.parent / f"products_{path_products.stem}_flat.csv"
    df.to_csv(fname_csv, index=False)
    fname_parquet = fname_csv.parent / f"{fname_csv.stem}.parquet"
    df.to_parquet(fname_parquet)
