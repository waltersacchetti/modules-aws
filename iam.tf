# ╔══════════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                             Module                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════════╝
resource "aws_iam_role" "this" {
  for_each           = { for k, v in var.aws.resources.iam : k => v if v.create_iam_role == true }
  name               = "${local.translation_regions[var.aws.region]}-${var.aws.profile}-iamrole-${each.key}"
  assume_role_policy = each.value.iam_role.assume_role_policy_jsonfile
  description        = "IAM role for ${each.key}"
  tags               = merge(local.common_tags, each.value.iam_role.tags)
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each   = { for k, v in var.aws.resources.iam : k => v if v.create_iam_role_policy_attachment == true }
  policy_arn = each.value.iam_role_policy_attachment.policy_arn
  role       = aws_iam_role.this[each.value.iam_role_policy_attachment.role].name
}

resource "aws_iam_instance_profile" "this" {
  for_each = { for k, v in var.aws.resources.iam : k => v if v.create_iam_instance_profile == true }
  name = "${local.translation_regions[var.aws.region]}-${var.aws.profile}-iam-instance-profile-${each.key}"
  role = aws_iam_role.this[each.value.iam_instance_profile.role].name
  tags = merge(local.common_tags, each.value.iam_instance_profile.tags)
}