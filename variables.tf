variable "aws" {
  description = "Main AWS Configuration"
  type =  map(object({
    region = string
    profile = string
    resources = var.resources
  }))
  default = {}
}

variable "resources" {
  description = "AWS Resources definition"
  type = map(object({
    vpc = var.vpc
    # eks = var.eks
    # rds = var.rds
    # ec2 = var.ec2
    # s3 = var.s3
  }))
  default = {}
}

variable "vpc" {
  description = "VPC Configuration"
  type = map(object({
    cidr = string
  }))
  default = {}
}

variable "translation_map" {
  type = map(string)
  default = {
    "euw1" = "eu-west-1"
  }
}


# variable "eks" {
#   description = "EKS Configuration"
#   type = map(object({
#     version = string
#     instance_type = string
#     min_size = number
#     max_size = number
#     desired_capacity = number
#     subnets = list(string)
#     vpc_id = string
#   }))
#   default = {}
# }

# variable "rds" {
#   description = "RDS Configuration"
#   type = map(object({
#     engine = string
#     engine_version = string
#     instance_class = string
#     username = string
#     password = string
#     allocated_storage = number
#     storage_type = string
#     vpc_security_group_ids = list(string)
#     vpc_subnet_ids = list(string)
#   }))
#   default = {}
# }

# variable "ec2" {
#   description = "EC2 Configuration"
#   type = map(object({
#     ami = string
#     instance_type = string
#     key_name = string
#     subnet_id = string
#     vpc_security_group_ids = list(string)
#   }))
#   default = {}
# }

# variable "s3" {
#   description = "S3 Configuration"
#   type = map(object({
#     bucket = string
#     acl = string
#     force_destroy = bool
#   }))
#   default = {}
# }