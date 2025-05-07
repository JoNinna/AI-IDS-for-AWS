resource "aws_s3_bucket" "log_bucket" {
  bucket = "hids-suricata-logs"
  acl    = "private"
}
