provider "aws" {
  region  = var.translation_map[var.aws.region]
  profile = var.aws.profile
}