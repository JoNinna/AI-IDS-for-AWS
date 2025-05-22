import json
import boto3

s3 = boto3.client('s3')

# ——— RULE-BASED LABELING ———

def assign_label_suricata(entry):
    method = entry.get("method")
    dest_ip = entry.get("dest_ip")
    url = entry.get("url") or ""
    user_agent = entry.get("user_agent")
    status = entry.get("status")
    src_ip = entry.get("src_ip")

    if (
        dest_ip == "169.254.169.254" and
        method in ["GET", "PUT"] and
        "/latest/meta-data" in url
    ):
        return 1

    if not user_agent or "unknown" in user_agent.lower():
        return 1

    if status and str(status) != "200":
        return 1

    if src_ip and not src_ip.startswith("10."):
        return 1

    return 0

def assign_label_falco(entry):
    output = (entry.get("output") or "").lower()
    rule = (entry.get("rule") or "").lower()

    if (
        "shell was spawned" in output or
        "command=sh" in output or
        "command=bash" in output or
        ("user=root" in output and "proc_exepath=/bin/busybox" in output)
    ):
        return 1

    if (
        "terminal shell in container" in rule or
        "unexpected network connection" in rule
    ):
        return 1

    return 0

# ——— LAMBDA HANDLER ———

def lambda_handler(event, context):
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key    = record['s3']['object']['key']

        # Filter JSON logs from correct prefixes
        if not key.endswith('.json') or not (key.startswith("suricata-logs/") or key.startswith("falco-logs/")):
            continue

        try:
            response = s3.get_object(Bucket=bucket, Key=key)
            body = response['Body'].read().decode('utf-8')

            try:
                json_obj = json.loads(body)
                lines = [json.dumps(entry) for entry in (json_obj if isinstance(json_obj, list) else [json_obj])]
            except json.JSONDecodeError:
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

            if key.startswith("suricata-logs/") and data.get("event_type") == "http":
                entry = {
                    "timestamp": data.get("timestamp"),
                    "src_ip": data.get("src_ip"),
                    "dest_ip": data.get("dest_ip"),
                    "method": data.get("http", {}).get("http_method"),
                    "url": data.get("http", {}).get("url"),
                    "status": data.get("http", {}).get("status"),
                    "user_agent": data.get("http", {}).get("http_user_agent")
                }
                entry["label"] = assign_label_suricata(entry)
                processed.append(entry)

            elif key.startswith("falco-logs/") and "output_fields" in data:
                entry = {
                    "timestamp": data.get("time"),
                    "priority": data.get("priority"),
                    "rule": data.get("rule"),
                    "output": data.get("output")
                }
                entry["label"] = assign_label_falco(entry)
                processed.append(entry)

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
