resource "aws_wafv2_web_acl" "waf" {
  for_each = var.aws.waf

  name        = each.value.name
  description = "Web ACL for ${each.value.name}"
  scope       = each.value.scope
  tags        = each.value.tags #merge(local.common_tags, each.value.tags)

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = each.value.visibility_config.cloudwatch_metrics_enabled
    metric_name                = each.value.visibility_config.metric_name
    sampled_requests_enabled   = each.value.visibility_config.sampled_requests_enabled
  }

  dynamic "rule" {
    for_each = each.value.rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      # Add other attributes from the map if needed
      statement {
        managed_rule_group_statement {
          name        = rule.value.statement.name
          vendor_name = rule.value.statement.vendor_name
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = rule.value.visibility_config.cloudwatch_metrics_enabled
        metric_name                = rule.value.visibility_config.metric_name
        sampled_requests_enabled   = rule.value.visibility_config.sampled_requests_enabled
      }

      override_action {
        none {}
      }
    }
  }
}


