variable "ami" {
  description = "ami_name"
  type = string 
}

variable "instance_type" {
  description = "instance_type"
  type        = string
}

variable "region" {
  description = "region"
  type        = string
}

variable "profile" {
  description = "profile"
  type        = string
}

variable "counter" {
  description = "Number of instances to launch"
  type        = number
}

variable "index" {
  description = "which index to output. 0 is 1st insance"
  type        = number
}

variable "instance_tag" {
  description = "Tag given to each deployed Instance"
  type = string 
}

variable "key_name" {
  description = "key_pair_name"
  type        = string
}
/*
variable "instance_tag" {
  description = "Tag given to each deployed Instance"
  type = string 
}

variable "counter" {
  description = "Number of instances to launch"
  type        = number
}

variable "file_name" {
  description = "Name of the key pair"
  type        = string
}

variable "cidr_block" {
  description = "CIDR Block"
  type = string
}

variable "availability_zone"{
  description = "Availability Zones for the Subnet"
  type = string
}
*/
