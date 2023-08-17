resource "aws_cloudfront_distribution" "cloudfront_distributions" {
  for_each = var.aws.cloudfront_distributions

  enabled             = each.value.enabled
  http_version        = each.value.http_version
  #web_acl_id          = each.value.web_acl_id #Or reference to another resource creat
  default_cache_behavior {
    allowed_methods            = each.value.default_cache_behavior.allowed_methods
    cache_policy_id            = each.value.default_cache_behavior.cache_policy_id
    cached_methods             = each.value.default_cache_behavior.cached_methods 
    compress                   = each.value.default_cache_behavior.compress   
    response_headers_policy_id = each.value.default_cache_behavior.response_headers_policy_id
    target_origin_id           = each.value.default_cache_behavior.target_origin_id
    viewer_protocol_policy     = each.value.default_cache_behavior.viewer_protocol_policy
  }
  origin {
    domain_name              = each.value.origin.domain_name
    origin_id                = each.value.origin.origin_id
    custom_origin_config {
      http_port                = each.value.origin.custom_origin_config.http_port                
      https_port               = each.value.origin.custom_origin_config.https_port               
      origin_protocol_policy   = each.value.origin.custom_origin_config.origin_protocol_policy   
      origin_ssl_protocols     = each.value.origin.custom_origin_config.origin_ssl_protocols     
    }
  }
  restrictions {
    geo_restriction {
      restriction_type = each.value.restrictions.restriction_type
      locations        = each.value.restrictions.locations       
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = each.value.viewer_certificate.cloudfront_default_certificate #acm_certificate_arn, cloudfront_default_certificate, iam_certificate_id, minimum_protocol_version, ssl_support_method
    minimum_protocol_version = each.value.viewer_certificate.minimum_protocol_version
  }

  #logging_config {
  #  bucket         =  each.value.logging_config.bucket        
  #  include_cookies = each.value.logging_config.include_cookies
  #}
  dynamic "ordered_cache_behavior" {
    for_each = each.value.ordered_cache_behavior

    content {
      allowed_methods            = ordered_cache_behavior.value.allowed_methods           
      cache_policy_id            = ordered_cache_behavior.value.cache_policy_id           
      cached_methods             = ordered_cache_behavior.value.cached_methods            
      compress                   = ordered_cache_behavior.value.compress                  
      path_pattern               = ordered_cache_behavior.value.path_pattern              
      response_headers_policy_id = ordered_cache_behavior.value.response_headers_policy_id
      target_origin_id           = ordered_cache_behavior.value.target_origin_id          
      viewer_protocol_policy     = ordered_cache_behavior.value.viewer_protocol_policy 
    } 
  }
}

resource "aws_cloudfront_cache_policy" "cache_policies" {
  for_each = var.aws.cloudfront_cache_policies
  default_ttl = each.value.default_ttl
  max_ttl     = each.value.max_ttl
  min_ttl     = each.value.min_ttl
  name        = each.value.name
  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = each.value.parameters_in_cache_key_and_forwarded_to_origin.enable_accept_encoding_brotli
    enable_accept_encoding_gzip   = each.value.parameters_in_cache_key_and_forwarded_to_origin.enable_accept_encoding_gzip
    cookies_config {
      cookie_behavior = each.value.parameters_in_cache_key_and_forwarded_to_origin.cookies_config.cookie_behavior
      cookies {
        items = each.value.parameters_in_cache_key_and_forwarded_to_origin.cookies_config.cookies
      }
    }
    headers_config {
      header_behavior = each.value.parameters_in_cache_key_and_forwarded_to_origin.headers_config.header_behavior
      headers {
        items = each.value.parameters_in_cache_key_and_forwarded_to_origin.headers_config.headers
      }
    }
    query_strings_config {
      query_string_behavior = each.value.parameters_in_cache_key_and_forwarded_to_origin.query_strings_config.query_string_behavior
      query_strings {
        items = each.value.parameters_in_cache_key_and_forwarded_to_origin.query_strings_config.query_strings
      }
    }
  }

}


