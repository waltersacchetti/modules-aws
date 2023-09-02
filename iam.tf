# ╔══════════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                             Module                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════════╝
resource "aws_iam_role" "this" {
  for_each           = { for k, v in var.aws.resources.iam : k => v if length(v.iam_role) > 0 }
  name               = "${local.translation_regions[var.aws.region]}-${var.aws.profile}-iamrole-${each.key}"
  assume_role_policy = each.value.iam_role.assume_role_policy_jsonfile
  description        = "IAM role for ${each.key}"
  tags               = merge(local.common_tags, each.value.iam_role.tags)
}



