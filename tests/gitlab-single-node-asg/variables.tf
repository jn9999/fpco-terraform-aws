variable "key_name" {
  description = "The name of the keypair to use"
}

variable "instance_type" {
  description = "The type of the EC2 instance to use"
}

variable "instance_ami" {
  description = "The EC2 image to use"
}

variable "region" {
  description = "The region for all of the resources"
}

variable "az" {
  description = "The availability zone to create the instance in"
}

variable "key_file" {
  description = "Path to the SSH private key to provide connection info as output"
}

variable "vpc_id" {
  description = "The VPC to put the security group on"
}

variable "subnet_id" {
  description = "The VPC subnet to put the instance on"
}

variable "root_volume_type" {
  default     = "gp2"
  description = "Type of EBS volume to use for the root block device"
}

variable "root_volume_size" {
  default     = "8"
  description = "Size (in GB) of EBS volume to use for the root block device"
}

variable "data_volume_type" {
  default     = "gp2"
  description = "Type of EBS volume to use for the EBS volume"
}

variable "data_volume_size" {
  default     = "10"
  description = "Size (in GB) of EBS volume to use for the EBS volume"
}

variable "data_volume_encrypted" {
  default     = "true"
  description = "Boolean, whether or not to encrypt the EBS block device"
}

variable "data_volume_kms_key_id" {
  default     = ""
  description = "ID of the KMS key to use when encyprting the EBS block device"
}

variable "data_volume_snapshot_id" {
  default     = ""
  description = "The ID of the snapshot to base the EBS block device on"
}

variable "data_volume_iops" {
  default     = ""
  description = "The amount of IOPS to provision for the EBS block device"
}