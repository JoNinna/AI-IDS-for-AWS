import json
import boto3

s3 = boto3.client('s3')

def lambda_handler(event, context):
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key    = record['s3']['object']['key']

        # Only process .json files from correct prefixes
        if not key.endswith('.json') or not (key.startswith("suricata-logs/") or key.startswith("falco-logs/")):
            continue

        try:
            response = s3.get_object(Bucket=bucket, Key=key)
            body = response['Body'].read().decode('utf-8')

            # Try to parse as a single JSON object or list
            try:
                json_obj = json.loads(body)
                if isinstance(json_obj, list):
                    lines = [json.dumps(entry) for entry in json_obj]
                else:
                    lines = [json.dumps(json_obj)]
            except json.JSONDecodeError:
                # Fallback to line-delimited parsing
                lines = body.strip().splitlines()

        except Exception as e:
            print(f"Error reading S3 object {key}: {e}")
            continue

        processed = []

        for line in lines:
            try:
                data = json.loads(line)
            except json.JSONDecodeError:
                continue

            if key.startswith("suricata-logs/"):
                if data.get("event_type") == "http":
                    processed.append({
                        "timestamp": data.get("timestamp"),
                        "src_ip": data.get("src_ip"),
                        "dest_ip": data.get("dest_ip"),
                        "method": data.get("http", {}).get("http_method"),
                        "url": data.get("http", {}).get("url"),
                        "status": data.get("http", {}).get("status"),
                        "user_agent": data.get("http", {}).get("http_user_agent")
                    })

            elif key.startswith("falco-logs/"):
                if "output_fields" in data:
                    processed.append({
                        "timestamp": data.get("time"),
                        "priority": data.get("priority"),
                        "rule": data.get("rule"),
                        "output": data.get("output")
                    })

        if processed:
            output_key = key.replace('suricata-logs/', 'processed/suricata/') \
                            .replace('falco-logs/', 'processed/falco/')
            try:
                s3.put_object(
                    Bucket=bucket,
                    Key=output_key,
                    Body='\n'.join(json.dumps(p) for p in processed).encode('utf-8'),
                    ContentType='application/json'
                )
                print(f"Uploaded {len(processed)} entries to {output_key}")
            except Exception as e:
                print(f"Failed to upload processed logs to {output_key}: {e}")

    return {"statusCode": 200, "body": "Processed successfully"}
