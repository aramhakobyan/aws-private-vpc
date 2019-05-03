variable "vpc_cidr_block" {
  description = "The top-level CIDR block for the VPC."
  default     = "10.1.0.0/16"
}

variable "az-count" {
  default = 3
}

variable "namespace" {
  default = "Development"
}


variable "region" {
  default = "us-west-2"
}

