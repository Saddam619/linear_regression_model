import io
import logging
from copy import deepcopy
from pathlib import Path

import joblib
import pandas as pd
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, field_validator
from sklearn.linear_model import SGDRegressor

BASE_DIR = Path(__file__).parent
MODEL_PATH = BASE_DIR / "best_model.pkl"
TRAINING_DATA_PATH = BASE_DIR / "training_data.csv"

NUMERIC_FEATURES = [
    "year",
    "gdp_growth",
    "gdp_per_capita",
    "inflation",
    "labor_force_participation",
    "population_growth",
    "urban_population",
    "trade_pct_gdp",
    "fdi_pct_gdp",
    "agriculture_pct_gdp",
    "industry_pct_gdp",
    "secondary_enrollment",
    "life_expectancy",
]
CATEGORICAL_FEATURES = ["country", "sub_region"]
FEATURE_COLUMNS = NUMERIC_FEATURES + CATEGORICAL_FEATURES
TARGET_COLUMN = "unemployment_rate"

COUNTRY_SUB_REGIONS = {
    "Algeria": "North",
    "Angola": "Central",
    "Benin": "West",
    "Botswana": "Southern",
    "Burkina Faso": "West",
    "Burundi": "East",
    "Cabo Verde": "West",
    "Cameroon": "Central",
    "Central African Republic": "Central",
    "Chad": "Central",
    "Comoros": "East",
    "Congo, Dem. Rep.": "Central",
    "Congo, Rep.": "Central",
    "Cote d'Ivoire": "West",
    "Djibouti": "East",
    "Egypt": "North",
    "Equatorial Guinea": "Central",
    "Eritrea": "East",
    "Eswatini": "Southern",
    "Ethiopia": "East",
    "Gabon": "Central",
    "Gambia": "West",
    "Ghana": "West",
    "Guinea": "West",
    "Guinea-Bissau": "West",
    "Kenya": "East",
    "Lesotho": "Southern",
    "Liberia": "West",
    "Libya": "North",
    "Madagascar": "East",
    "Malawi": "East",
    "Mali": "West",
    "Mauritania": "West",
    "Mauritius": "East",
    "Morocco": "North",
    "Mozambique": "East",
    "Namibia": "Southern",
    "Niger": "West",
    "Nigeria": "West",
    "Rwanda": "East",
    "Sao Tome and Principe": "Central",
    "Senegal": "West",
    "Seychelles": "East",
    "Sierra Leone": "West",
    "Somalia": "East",
    "South Africa": "Southern",
    "South Sudan": "East",
    "Sudan": "North",
    "Tanzania": "East",
    "Togo": "West",
    "Tunisia": "North",
    "Uganda": "East",
    "Zambia": "East",
    "Zimbabwe": "East",
}
COUNTRY_LOOKUP = {name.casefold(): name for name in COUNTRY_SUB_REGIONS}

app = FastAPI(title="Africa Unemployment Prediction API")

# Browser access is limited to the configured service domain and local debug
# addresses; other origins are restricted. Native mobile apps are not browsers,
# so CORS does not apply to them.
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        # TODO: REPLACE WITH YOUR NEW RENDER URL (no trailing slash)
        "PASTE_YOUR_RENDER_API_URL_HERE",
        "http://localhost:8080",
        "http://127.0.0.1:8080",
        "http://localhost:5000",
        "http://127.0.0.1:5000",
    ],
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Accept"],
    allow_credentials=False,
)

model = joblib.load(MODEL_PATH)
training_row_count = len(pd.read_csv(TRAINING_DATA_PATH))


def canonical_country(value: str) -> str:
    country = COUNTRY_LOOKUP.get(value.strip().casefold())
    if country is None:
        raise ValueError("Country must be one of the 54 African countries in the training data.")
    return country


class PredictionInput(BaseModel):
    year: int = Field(ge=1991, le=2030, strict=True)
    gdp_growth: float = Field(ge=-60, le=150, strict=True)
    gdp_per_capita: float = Field(ge=0, le=250000, strict=True)
    inflation: float = Field(ge=-30, le=5000, strict=True)
    labor_force_participation: float = Field(ge=0, le=100, strict=True)
    population_growth: float = Field(ge=-10, le=15, strict=True)
    urban_population: float = Field(ge=0, le=100, strict=True)
    trade_pct_gdp: float = Field(ge=0, le=500, strict=True)
    fdi_pct_gdp: float = Field(ge=-100, le=500, strict=True)
    agriculture_pct_gdp: float = Field(ge=0, le=100, strict=True)
    industry_pct_gdp: float = Field(ge=0, le=100, strict=True)
    secondary_enrollment: float = Field(ge=0, le=200, strict=True)
    life_expectancy: float = Field(ge=20, le=100, strict=True)
    country: str

    @field_validator("country")
    @classmethod
    def validate_country(cls, value: str) -> str:
        return canonical_country(value)


@app.post("/predict")
def predict(data: PredictionInput) -> dict[str, float]:
    row = data.model_dump()
    row["sub_region"] = COUNTRY_SUB_REGIONS[row["country"]]
    input_frame = pd.DataFrame([row], columns=FEATURE_COLUMNS)
    prediction = model.predict(input_frame)[0]
    return {"predicted_unemployment_rate": round(float(prediction), 2)}


@app.post("/retrain")
def retrain(file: UploadFile = File(...)) -> dict[str, int | str | bool]:
    global model, training_row_count

    try:
        new_data = pd.read_csv(io.BytesIO(file.file.read()))
    except (UnicodeDecodeError, pd.errors.ParserError) as error:
        raise HTTPException(status_code=400, detail="Uploaded file must be a readable CSV.") from error

    required_columns = set(NUMERIC_FEATURES + ["country", TARGET_COLUMN])
    missing_columns = sorted(required_columns - set(new_data.columns))
    if missing_columns:
        raise HTTPException(
            status_code=400,
            detail=f"Uploaded CSV is missing required columns: {', '.join(missing_columns)}",
        )

    new_data = new_data.dropna(subset=[TARGET_COLUMN]).copy()
    if new_data.empty:
        raise HTTPException(status_code=400, detail="Uploaded CSV contains no rows with a target value.")

    try:
        new_data["country"] = new_data["country"].map(canonical_country)
    except (AttributeError, ValueError) as error:
        raise HTTPException(status_code=400, detail=str(error)) from error

    if "sub_region" not in new_data.columns:
        new_data["sub_region"] = new_data["country"].map(COUNTRY_SUB_REGIONS)

    new_rows = len(new_data)
    updated_model = deepcopy(model)

    if isinstance(updated_model.named_steps["model"], SGDRegressor):
        preprocessor = updated_model.named_steps["preprocessor"]
        estimator = updated_model.named_steps["model"]
        estimator.partial_fit(
            preprocessor.transform(new_data[FEATURE_COLUMNS]),
            new_data[TARGET_COLUMN],
        )
        new_row_count = training_row_count + new_rows
    else:
        training_data = pd.read_csv(TRAINING_DATA_PATH)
        if "sub_region" not in training_data.columns:
            training_data["sub_region"] = training_data["country"].map(COUNTRY_SUB_REGIONS)
        combined_data = pd.concat([training_data, new_data], ignore_index=True)
        updated_model.fit(
            combined_data[FEATURE_COLUMNS],
            combined_data[TARGET_COLUMN],
        )
        new_row_count = len(combined_data)

    model = updated_model
    training_row_count = new_row_count

    persisted = True
    try:
        joblib.dump(model, MODEL_PATH)
    except Exception:
        logging.exception("The updated model is active but could not be saved to disk.")
        persisted = False

    return {
        "rows_added": new_rows,
        "new_row_count": new_row_count,
        "model_persisted": persisted,
        "message": "Model updated successfully.",
    }
