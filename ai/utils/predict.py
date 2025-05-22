# predict.py
import pandas as pd
import joblib
from .preprocessing import preprocess_dataframe

def predict_from_csv(model, path, label_field=None):
    df = pd.read_csv(path)
    df_processed, _, _ = preprocess_dataframe(df, label_field=label_field)

    # Elimină coloana de label dacă este prezentă
    if label_field and label_field in df_processed.columns:
        df_processed = df_processed.drop(columns=[label_field])

    return model.predict(df_processed)

def predict_from_json(model_path, log_json_path, label_field=None):
    """
    Încarcă modelul și aplică predicții pe loguri JSON.
    """
    model = joblib.load(model_path)
    df = pd.read_json(log_json_path, lines=True)

    # Preprocesare
    df_processed, _, _ = preprocess_dataframe(df, label_field=label_field)

    if label_field and label_field in df_processed.columns:
        df_processed = df_processed.drop(columns=[label_field])

    predictions = model.predict(df_processed)
    return predictions
