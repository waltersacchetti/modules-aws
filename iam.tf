resource "aws_iam_role" "this" {
  for_each           = var.aws.resources.iam
  assume_role_policy = each.value.policy
  tags               = merge(local.common_tags, each.value.tags)
}
