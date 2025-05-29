import boto3
import json
import os
import numpy as np
import logging

s3_client = boto3.client('s3')
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Calea către modelul inclus în arhivă
MODEL_PATH = "ai/models/model_cicids.pt"
model = joblib.load(MODEL_PATH)

def lambda_handler(event, context):
    try:
        # 1. Identificare fișier JSON nou în S3
        record = event['Records'][0]
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        
        logger.info(f"Received new object: s3://{bucket}/{key}")
        
        # 2. Descarcă fișierul JSON din S3
        response = s3_client.get_object(Bucket=bucket, Key=key)
        body = response['Body'].read().decode('utf-8')
        
        # 3. Parsează fiecare linie JSON
        labels = []
        lines = body.strip().splitlines()
        for line in lines:
            try:
                entry = json.loads(line)
                if "label" in entry:
                    labels.append(entry["label"])
            except json.JSONDecodeError:
                continue

        if not labels:
            logger.warning("No labels found in log file.")
            return {"statusCode": 204, "body": "No labels found"}

        # 4. Creează input dummy cu același număr de feature-uri
        n_samples = len(labels)
        n_features = model.n_features_in_
        X_dummy = np.zeros((n_samples, n_features))

        # 5. Predicție binară și acuratețe
        predicted = model.predict(X_dummy)
        accuracy = (predicted == labels).mean()
        
        logger.info(f"Predictions complete. Accuracy: {accuracy:.2%}")
        return {
            "statusCode": 200,
            "body": json.dumps({
                "accuracy": round(accuracy, 4),
                "samples": n_samples
            })
        }

    except Exception as e:
        logger.error(f"Error in inference Lambda: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
