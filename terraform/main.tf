provider "aws" {
  version = "~> 2.0"
  region  = var.region
}

terraform {
  backend "s3" {
    # bucket = "jk-tf-remote-state-from-local"
    bucket = "jk-tf-remote-state-from-actions"
    key    = "terraform-state"
    region = "us-east-1"
  }
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

# resource "aws_iam_role" "jk-lambda-s3-cloudfront-v3" {
#   name = "jk-lambda-s3-cloudfront-v3"
#   policy = file("lambdapolicy.json")
# }

data "aws_iam_role" "jk-lambda-s3-cloudfront2" {
  name = "jk-lambda-s3-cloudfront2"
}

data "archive_file" "lambda-s3-cf-func" {
  type        = "zip"
  source_dir  = "../lambda/"
  output_path = "./lambda-s3-cf.zip"
}

resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.jk-lambda-s3-v4.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.b.arn
}

resource "aws_lambda_function" "jk-lambda-s3-v4" {
  filename         = data.archive_file.lambda-s3-cf-func.output_path
  source_code_hash = data.archive_file.lambda-s3-cf-func.output_base64sha256
  function_name    = "jk-lambda-s3-v4"
  description      = "Trigger CloudFront invalidation on S3 bucket update"
  role             = data.aws_iam_role.jk-lambda-s3-cloudfront2.arn
  handler          = "s3-bucket-cf-invalidation.handler"
  runtime          = "nodejs12.x"
  timeout          = "60"
  memory_size      = "128"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.b.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.jk-lambda-s3-v4.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".html"
  }
}

data "aws_acm_certificate" "cert" {
  domain = "*.${var.domain}"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "via terraform"
}

resource "aws_cloudfront_distribution" "jk-distribution" {
  origin {
    domain_name = aws_s3_bucket.b.bucket_regional_domain_name
    origin_id   = var.s3_origin_id
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  comment             = "via terraform"
  default_root_object = "index.html"

  price_class      = "PriceClass_200"
  retain_on_delete = true

  aliases = ["${var.subdomain}.fourth-sandbox.com"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.s3_origin_id
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  viewer_certificate {
    acm_certificate_arn = data.aws_acm_certificate.cert.arn
    ssl_support_method  = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

data "aws_route53_zone" "domain" {
  name = var.domain
}

resource "aws_route53_record" "cf-subdomain" {
  zone_id = data.aws_route53_zone.domain.zone_id
  name    = var.subdomain
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.jk-distribution.domain_name
    zone_id                = aws_cloudfront_distribution.jk-distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# To Do:
# - provision role for lambda
# - update workflow to use tf v0.12.19
# - inject variable into policy json
