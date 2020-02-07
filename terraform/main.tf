provider "aws" {
  version = "~> 2.0"
  region  = var.region
}

terraform {
  backend "s3" {
    bucket = "jk-remote-state"
    key = "terraform-state"
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

# data "terraform_remote_state" "state"  {
#   backend = "s3"
#   config {
#     bucket = "${var.tf_state_bucket}"
#     key    = "terraform-state"
#     region = "${var.region}"
#   }
# }

# resource "aws_route53_zone" "fourth-sandbox" {
#   name = "fourth-sandbox.com"
# }

# data "aws_route53_zone" "fourth-sandbox" {
#   zone_id = Z2CCAX42E3UPIK
#   # name = "fourth-sandbox.com."
#   # private_zone = true
# }
 
resource "aws_route53_record" "s3-origin" {
  zone_id = "Z2CCAX42E3UPIK"
  # zone_id = data.aws_route53_zone.fourth-sandbox.zone_id
  name = "jk-s3-origin"
  type = "A"

  alias {
    name = aws_s3_bucket.b.website_endpoint
    zone_id = aws_s3_bucket.b.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Some comment"
}

resource "aws_cloudfront_distribution" "jk-distribution" {
  origin {
    # domain_name = "jibhi-test-bucket.s3-website-us-east-1.amazonaws.com"
    # domain_name = aws_s3_bucket.b.website_endpoint
    domain_name = aws_s3_bucket.b.bucket_regional_domain_name
    origin_id = "jk-s3-origin-id"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled = true
  default_root_object = "index.html"

  aliases = ["jk-test.fourth-sandbox.com"]
  price_class = "PriceClass_200"
  retain_on_delete = true
  
  default_cache_behavior {
    allowed_methods = [ "DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT" ]
    cached_methods = [ "GET", "HEAD" ]
    target_origin_id = "jk-s3-origin-id"
    forwarded_values {
      query_string = true
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
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}