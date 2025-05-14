resource "aws_s3_bucket" "log_bucket" {
  bucket = "hids-logs"
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket                  = aws_s3_bucket.log_bucket.id
  block_public_acls       = true #Prevents new public ACLs on objects in this bucket.
  block_public_policy     = true #Prevents public bucket policies.
  ignore_public_acls      = true #Makes all existing ACLs irrelevant; even if public, they’re ignored.
  restrict_public_buckets = true #Ensures policies can't be modified to allow public access.
}
