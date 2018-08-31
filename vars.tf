variable "key_file" {
  description = "Full path to the ssh keypair for logging into systems"
  //default = "/home/dsmk/.ssh/buaws-websites-nonprod-dsmk.pem"
  default = "/home/dsmk/.ssh/buaws-sandbox-dsmk.pem"
}

variable "key_name" {
  description = "Name of SSH keypair to use in AWS."
  //default = "buaws-websites-nonprod-dsmk"
  default = "dsmk"
}

variable "subnet_id" {
  description = "Subnet for our resources"
  default = "subnet-835087cb"
}

variable "vpc_id" {
  // buaws-sandbox-vpc in sandbox account
  default = "vpc-64c1c002"
}

