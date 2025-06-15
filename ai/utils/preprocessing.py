import pandas as pd

def load_csv_data(file_path):
    df = pd.read_csv(file_path, encoding='latin1', low_memory=False) 
    df.columns = df.columns.str.strip()
    return df

import json
import os

# PENTRU IMBUNATATIRI VIITOARE! 
# def load_json_data(file_path):
#     data = []
#     with open(file_path) as f:
#         for line in f:
#             data.append(json.loads(line))
#     return pd.DataFrame(data)

# def standardize_column_names(df):
#     column_mapping = {
#         'Source IP': 'src_ip',
#         'Destination IP': 'dest_ip',
#         'Timestamp': 'timestamp',
#     }
#     return df.rename(columns=lambda col: column_mapping.get(col, col))

# def extract_features(df):
#     df = df.copy()
#     df['timestamp'] = pd.to_datetime(df['timestamp'], errors='coerce')

#     # Feature: hour of day
#     df['hour'] = df['timestamp'].dt.hour.fillna(0).astype(int)

#     # Frequency of IP occurrences
#     df['source_ip_count'] = df['source_ip'].map(df['source_ip'].value_counts())
#     df['destination_ip_count'] = df['destination_ip'].map(df['destination_ip'].value_counts())

#     # Protocol one-hot
#     if 'protocol' in df.columns:
#         proto_dummies = pd.get_dummies(df['protocol'], prefix='proto')
#         df = pd.concat([df, proto_dummies], axis=1)

#     # Drop unused or high cardinality fields
#     df.drop(columns=['source_ip', 'destination_ip', 'protocol', 'timestamp'], inplace=True, errors='ignore')
    
#     return df

# def preprocess_for_training(df, label_field='label', standardize_columns=False):
#     # Curăță numele coloanelor de spații
#     df.columns = df.columns.str.strip()

#     if 'Label' in df.columns:
#         df.rename(columns={'Label': 'label'}, inplace=True)
    
#     if standardize_columns:
#         df = standardize_column_names(df)

#     if label_field not in df.columns:
#         raise ValueError(f"Missing label field: {label_field} Available columns: {df.columns.tolist()}")

#     y = df[label_field]
#     df = df.drop(columns=[label_field])

#     X = extract_features(df)

#     # Fill NA and normalize if needed
#     X = X.fillna(0)

#     return X, y
