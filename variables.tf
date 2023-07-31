variable "aws" {
  description   = "Main AWS Configuration"
  type          = object({
    region      = string
    profile     = string
    resources   = object({
        vpc     = map(object({
          cidr  = string
        }))
    })
  })
}
variable "translation_map" {
  type      = map(string)
  default   = {
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