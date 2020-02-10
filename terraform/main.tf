provider "aws" {
  version = "~> 2.0"
  region  = var.region
}

terraform {
  backend "s3" {
    # bucket = "jk-tf-remote-state-from-local"
    bucket = "jk-tf-remote-state-from-actions"
    key = "terraform-state"
    region = "us-east-1"
  }
}

locals {
  s3_origin_id = "jk-s3-id"
}

resource "aws_s3_bucket" "b" {
  bucket = var.bucket_name
  acl    = "public-read"

  versioning {
    enabled = true
  }

  tags = {
    Name = "JK S3 Test Bucket"
  }

  policy = file("policy.json")

  website {
    index_document = "index.html"
  }
}

data "archive_file" "lambda-s3-cf" {
  type = "zip"
  source_dir = "../lambda/"
  output_path = "./lambda-s3-cf.zip"
}

# resource "aws_iam_role" "jk-lambda-s3-cloudfront-v3" {
#   name = "jk-lambda-s3-cloudfront-v3"
#   policy = file("lambdapolicy.json")
# }

resource "aws_lambda_function" "jk-lambda-s3-v4" {
  function_name = "jk-lambda-s3-v4"
  handler = "s3-bucket-cf-invalidation.handler"
  runtime = "nodejs12.x"
  filename = "lambda-s3-cf.zip"
  source_code_hash = filebase64sha256("lambda-s3-cf.zip")
  role = "arn:aws:iam::153027161823:role/jk-lambda-s3-cloudfront2"
}

resource "aws_lambda_permission" "test" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.jk-lambda-s3-v4.arn
  principal = "s3.amazonaws.com"
  source_arn = "arn:aws:s3:::jibhi-test-bucket"
  # source_arn = aws_s3_bucket.b.arn
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "via terraform"
}

resource "aws_cloudfront_distribution" "jk-distribution" {
  origin {
    domain_name = aws_s3_bucket.b.bucket_regional_domain_name
    origin_id = local.s3_origin_id
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled = true
  comment = "via terraform"
  default_root_object = "index.html"

  price_class = "PriceClass_200"
  retain_on_delete = true

  aliases = ["jk1.fourth-sandbox.com"]
  
  default_cache_behavior {
    allowed_methods = [ "DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT" ]
    cached_methods = [ "GET", "HEAD" ]
    target_origin_id = local.s3_origin_id
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "allow-all"
    min_ttl = 0
    default_ttl = 3600
    max_ttl = 86400
  }
  
  viewer_certificate {
    # cloudfront_default_certificate = true
    acm_certificate_arn = "arn:aws:acm:us-east-1:153027161823:certificate/7b4e67b8-b054-4ced-bd2d-36cf81dc6ea1"
    ssl_support_method = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}