output "website_domain" {
  value = aws_s3_bucket.b.website_domain
}

output "website_endpoint" {
  value = aws_s3_bucket.b.website_endpoint
}
