output "suricata_instance_public_ip" {
  description = "Public IP of the Suricata EC2 instance"
  value       = aws_instance.suricata_server.public_ip
}

output "falco_instance_public_ip" {
  description = "Public IP of the Falco EC2 instance"
  value       = aws_instance.falco_server.public_ip
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket used for log storage"
  value       = aws_s3_bucket.log_bucket.bucket
}

output "ssh_access_command" {
  description = "SSH command to connect to the Suricata instance"
  value       = "ssh -i ${var.private_key_path} admin@${aws_instance.suricata_server.public_ip}"
}
