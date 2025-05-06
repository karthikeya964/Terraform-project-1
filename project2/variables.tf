# variables.tf

variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "vpc_b_cidr" {
  description = "CIDR block for VPC-B"
  type        = string
}

variable "vpc_b_name" {
  description = "Name for VPC-B"
  type        = string
}

variable "public_subnet_b_cidr" {
  description = "CIDR block for the public subnet in VPC-B"
  type        = string
}

variable "private_subnet_b_cidr" {
  description = "CIDR block for the private subnet in VPC-B"
  type        = string
}

variable "availability_zone_1" {
  description = "Availability Zone 1"
  type        = string
}

variable "availability_zone_2" {
  description = "Availability Zone 2"
  type        = string
}
