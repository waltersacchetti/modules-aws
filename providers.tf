provider "aws" {
  region  = var.translation_regions[var.aws.region]
  profile = var.aws.profile
}