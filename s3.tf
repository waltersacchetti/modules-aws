module "s3" {
  source                    = "terraform-aws-modules/s3-bucket/aws"
  version                   = "3.14.1"
  for_each                  = var.aws.resources.s3
  bucket                    = "${var.aws.region}-${var.aws.profile}-bucket-${each.key}"
  force_destroy             = each.value.force_destroy
  tags                      = merge(local.common_tags, each.value.tags)
  object_lock_enabled       = length(each.value.object_lock_configuration) == 0 ? false : true
  object_lock_configuration = each.value.object_lock_configuration
  versioning                = each.value.versioning
  attach_policy             = each.value.iam == "" ? false : true
  policy                    = data.aws_iam_policy_document.s3[each.key].json
  acl                       = each.value.public == false ? "private" : "public-read" 
  block_public_acls         = each.value.public == false ?  true : false 
  ignore_public_acls        = each.value.public == false ?  true : false 
  block_public_policy       = each.value.public == false ?  true : false 
  restrict_public_buckets   = each.value.public == false ?  true : false 
  control_object_ownership  = true
  object_ownership          = "BucketOwnerPreferred"
}