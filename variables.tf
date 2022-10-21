variable "vpc_id" {
  description = "VPC ID to use for AWS resources"
  default = "vpc-00c4c78c22e1922a9"
}

variable "subnet1_id" {
  description = "The first subnet to use"
  default = "subnet-0b21f234b0f4fc6d4"
}

variable "subnet2_id" {
  description = "The second subnet to use"
  default = "subnet-0bf1f7a7538566a79"
}
