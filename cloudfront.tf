resource "aws_cloudfront_distribution" "distribution" {
  origin {
    domain_name = element(regex(aws_api_gateway_stage.devstage.invoke_url, "//(.*?)/)",0)
    origin_id   = "apigateway"
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "PySpy"

  #  aliases = ["pyspy.toger.us"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "apigateway"

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 5
    max_ttl                = 5
  }

  price_class = "PriceClass_100"

  restrictions {
    restriction_type = "none"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
