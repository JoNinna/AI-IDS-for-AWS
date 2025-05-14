#Creates an IAM role named ec2-s3-write-role and Grants EC2 instances permission to assume this role
resource "aws_iam_role" "ec2_s3_write_role" {
  name = "ec2-s3-write-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

#Attaches a policy to the IAM role above. This policy allows to upload files and to modify permissions on those files, only to the objects inside the S3 bucket ${aws_s3_bucket.log_bucket.arn}/*
resource "aws_iam_role_policy" "ec2_s3_policy" {
  name = "ec2-s3-access"
  role = aws_iam_role.ec2_s3_write_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:ListBucket"
        ],
        Resource = [
          "${aws_s3_bucket.log_bucket.arn}",
          "${aws_s3_bucket.log_bucket.arn}/*"
        ]
      }
    ]
  })
}

#Creates an IAM instance profile named ec2-s3-profile and links it to the IAM role above.
#EC2 instances can't directly use an IAM role — they use an instance profile, which wraps a role.
resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name = "ec2-s3-profile"
  role = aws_iam_role.ec2_s3_write_role.name
}

# Lambda execution role (Allows Lambda to assume the role)
resource "aws_iam_role" "lambda_role" {
  name = "lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Attaching the basic Lambda execution policy for logs
resource "aws_iam_policy_attachment" "lambda_logs" {
  name       = "attach-lambda-logs"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# S3 access policy for Lambda
resource "aws_iam_role_policy" "s3_access" {
  name = "lambda-s3-access"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "s3:GetObject",
        "s3:PutObject"
      ],
      Resource = [
        "${aws_s3_bucket.log_bucket.arn}/*"
      ]
    }]
  })
}
