resource "aws_s3_bucket" "resume" {
  provider = aws.us_east_2
  bucket   = "resume-bachelder"

  tags = {
    Project = "cloud-resume"
  }
}

resource "aws_s3_bucket_public_access_block" "resume" {
  provider = aws.us_east_2
  bucket   = aws_s3_bucket.resume.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "resume" {
  name                              = "resume-bachelder-oac"
  description                       = "OAC for resume.bachelder.me"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_bucket_policy" "resume" {
  provider = aws.us_east_2
  bucket   = aws_s3_bucket.resume.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAC"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.resume.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.resume.arn
          }
        }
      }
    ]
  })
}

resource "aws_cloudfront_distribution" "resume" {
  enabled             = true
  default_root_object = "index.html"
  aliases             = [var.domain_name]
  price_class         = "PriceClass_All"
  is_ipv6_enabled     = true
  web_acl_id          = var.web_acl_id

  origin {
    domain_name              = aws_s3_bucket.resume.bucket_regional_domain_name
    origin_id                = "s3-resume-bachelder"
    origin_access_control_id = aws_cloudfront_origin_access_control.resume.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-resume-bachelder"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Project = "cloud-resume"
  }
}
