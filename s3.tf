# ╔══════════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                             Locals                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════════╝
locals {
  s3_list_policy = flatten([
    for key, value in var.aws.resources.s3 : [
      value.iam != "" ? {
        bucket = key
        policy = value.iam
      } : null
    ]
  ])

  s3_map_policy = {
    for policy in local.s3_list_policy : policy.bucket => policy.policy
  }
}

# ╔══════════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                             Data                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════════╝
# Configure with the necessary bucket policy
data "aws_iam_policy_document" "s3" {
  for_each = local.s3_map_policy
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.this[each.value].arn]
    }
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${local.translation_regions[var.aws.region]}-${var.aws.profile}-bucket-${each.key}",
    ]
  }
}

# ╔══════════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                             Module                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════════╝
module "s3" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  version       = "3.14.1"
  for_each      = var.aws.resources.s3
  bucket        = "${local.translation_regions[var.aws.region]}-${var.aws.profile}-bucket-${each.key}"
  force_destroy = each.value.force_destroy
  tags          = merge(local.common_tags, each.value.tags)
  versioning    = each.value.versioning

  # Enable if necessary
  # object_lock_enabled       = length(each.value.object_lock_configuration) == 0 ? false : true
  # object_lock_configuration = each.value.object_lock_configuration

  # Configure with the necessary bucket policy in aws_iam_policy_document data block
  attach_policy = true
  policy        = data.aws_iam_policy_document.s3[each.key].json
}