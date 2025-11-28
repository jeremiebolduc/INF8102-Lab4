variable "project" {
  default = "polystudent"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "az1" {
  default = "ca-central-1a"
}

variable "az2" {
  default = "ca-central-1b"
}

variable "public_subnet_az1_cidr" {
  default = "10.0.0.0/24"
}

variable "public_subnet_az2_cidr" {
  default = "10.0.16.0/24"
}

variable "private_subnet_az1_cidr" {
  default = "10.0.128.0/24"
}

variable "private_subnet_az2_cidr" {
  default = "10.0.144.0/24"
}
