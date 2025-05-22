import json
import pandas as pd
from sklearn.preprocessing import LabelEncoder

def load_cicids_csv(path: str) -> pd.DataFrame:
    df = pd.read_csv(path)
    return df

def preprocess_cicids(df: pd.DataFrame) -> tuple:
    # Elimină coloane inutile dacă există
    cols_to_drop = ['Flow ID', 'Source IP', 'Destination IP', 'Timestamp', 'Label'] if 'Label' in df.columns else []
    X = df.drop(columns=[col for col in cols_to_drop if col in df.columns], errors='ignore')

    # Encodează labelul
    y = None
    if 'Label' in df.columns:
        le = LabelEncoder()
        y = le.fit_transform(df['Label'])
    return X, y

def load_json_logs(file_path):
    """Load a JSON log file with one JSON object per line."""
    with open(file_path, 'r') as f:
        lines = [json.loads(line) for line in f if line.strip()]
    return pd.DataFrame(lines)

def preprocess_dataframe(df, label_field=None, required_features=None):
    """Preprocess the DataFrame: handle missing, encode, extract features."""
    df = df.copy()

    # Drop columns with too many NaNs or only 1 unique value
    df = df.dropna(axis=1, thresh=0.5 * len(df))
    df = df.loc[:, df.nunique() > 1]

    # Encode categorical features
    encoders = {}
    for col in df.select_dtypes(include='object').columns:
        if col == label_field:
            continue
        le = LabelEncoder()
        try:
            df[col] = le.fit_transform(df[col].astype(str))
            encoders[col] = le
        except:
            df = df.drop(columns=[col])

    # Encode label if present
    label_encoder = None
    classes_ = None
    if label_field and label_field in df.columns:
        label_encoder = LabelEncoder()
        df[label_field] = label_encoder.fit_transform(df[label_field].astype(str))
        classes_ = label_encoder.classes_

    # Align features if provided
    if required_features:
        df = align_features(df, required_features)

    return df, encoders, label_encoder, classes_