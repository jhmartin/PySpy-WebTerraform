resource "aws_cloudfront_distribution" "distribution" {
  origin {
    domain_name = element(regex("^https?://([^/:]+)", aws_api_gateway_stage.devstage.invoke_url), 0)
    origin_id   = "apigateway"

    custom_origin_config {
      http_port                = 80             # The HTTP port the custom origin listens on
      https_port               = 443            # The HTTPS port the custom origin listens on
      origin_protocol_policy   = "match-viewer" # Match the protocol with the viewer
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_keepalive_timeout = 5
      origin_read_timeout      = 30
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "PySpy"

  #  aliases = ["pyspy.toger.us"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
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

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_cloudfront_cache_policy" "pyspy" {
  name        = "PyApi-Cache"
  comment     = "Just allow relevent values"
  default_ttl = 5
  max_ttl     = 10
  min_ttl     = 1
  parameters_in_cache_key_and_forwarded_to_origin {

    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "whitelist"
      query_strings {
        items = ["character_id"]
      }
    }
  }
}

resource "aws_cloudfront_origin_request_policy" "pyspy" {
  name    = "PyApi-Cache"
  comment = "Just allow relevant values"
  cookies_config {
    cookie_behavior = "none"
  }
  headers_config {
    header_behavior = "none"
  }
  query_strings_config {
    query_string_behavior = "whitelist"
    query_strings {
      items = ["character_id"]
    }
  }
}
