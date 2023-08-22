# IAM role for s3 bucket policy
resource "aws_iam_role" "this" {
  for_each           = var.aws.resources.iam
  name               = "${local.translation_regions[var.aws.region]}-${var.aws.profile}-iamrole-${each.key}"
  assume_role_policy = each.value.policy
  description        = "IAM role for ${each.key}"
  tags               = merge(local.common_tags, each.value.tags)
}