
provider "aws" {
  version = "~> 2.0"
  region  = "${var.aws_region}"
}

terraform {
  backend "s3" {
    bucket = "jk-remote-state"
    key    = "terraform-state"
    region = "${var.region}"
  }
}

resource "aws_s3_bucket" "b" {
  bucket = "${var.bucket_name}"
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
