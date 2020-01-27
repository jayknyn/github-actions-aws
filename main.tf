
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

  website {
    index_document = "index.html"
  }
}

# resource "aws_s3_bucket" "v" {
#   bucket = "jk-demo-bucket2"
#   acl    = "public-read"

#   # versioning {
#   #   enabled = true
#   # }

#   #   policy = <<EOF
#   # {
#   #   "Id": "MakePublic",
#   #   "Version": "2012-10-17",
#   #   "Statement": [
#   #     {
#   #       "Action": [
#   #         "s3:GetObject"
#   #       ],
#   #       "Effect": "Allow",
#   #       "Resource": "arn:aws:s3:::jk-remote-state/*",
#   #       "Principal": "*"
#   #     }
#   #   ]
#   # }
#   # EOF

#   website {
#     index_document = "index.html"
#   }
# }

# resource "aws_instance" "jkdemo" {
#   ami           = "ami-062f7200baf2fa504"
#   instance_type = "t2.micro"
#   tags = {
#     Name = "jkdemo2"
#   }
# }
