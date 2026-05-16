variable "domain_name" {
  description = "Custom domain for the resume site"
  type        = string
  default     = "resume.bachelder.me"
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate (must be in us-east-1 for CloudFront)"
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "Existing CloudFront distribution ID (used by deploy-frontend workflow)"
  type        = string
  default     = "EFO7NKGHS2UOM"
}

variable "web_acl_id" {
  description = "ARN of the WAF web ACL attached to the CloudFront distribution"
  type        = string
}
