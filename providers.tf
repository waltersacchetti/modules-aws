provider "aws" {
  region  = lookup(var.translation_map, var.aws.region, "")
  profile = var.aws.profile
}