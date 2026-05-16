output "s3_bucket_name" {
  description = "Name of the S3 bucket hosting resume static files"
  value       = aws_s3_bucket.resume.bucket
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (used in deploy-frontend workflow)"
  value       = aws_cloudfront_distribution.resume.id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain (set this as CNAME target in Cloudflare)"
  value       = aws_cloudfront_distribution.resume.domain_name
}

output "resume_url" {
  description = "Live URL of the resume site"
  value       = "https://${var.domain_name}"
}
