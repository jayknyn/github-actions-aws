
provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "jk-remote-state"
    key    = "terraform-state"
    region = "us-east-1"
  }
}

resource "aws_s3_bucket" "b" {
  bucket = "jibhi-test-bucket"
  acl    = "public-read"

  versioning {
    enabled = true
  }

  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::jibhi-test-bucket/*"
            ]
        }
    ]
}
EOF

  website {
    index_document = "index.html"
  }
}
