provider "aws" {
  region  = var.translation_regions[var.aws.region]
  profile = var.aws.profile
}

terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.1.0" # Reemplaza esto con la versión adecuada del proveedor "random"
    }
  }
}
