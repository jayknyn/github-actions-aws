
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

  policy = "${file("policy.json")}"

  website {
    index_document = "index.html"
  }
}
