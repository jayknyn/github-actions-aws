
provider "aws" {
  version = "~> 2.0"
  region  = var.region
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

  tags = {
    Name = "JK S3 Test Bucket"
  }

  policy = "${file("policy.json")}"

  website {
    index_document = "index.html"
  }
}
