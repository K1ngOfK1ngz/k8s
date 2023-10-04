variable cidr_block {
  type        = string
  description = "VPC CIDR Block"
}

variable vpc_name {
  type        = string
  description = "VPC Name"
}

variable region {
  type        = string
  default     = "us-east-1"
  description = "Region name"
}

variable private_subnet01_netnumber {
  type        = string
  description = "Private subenet"
}

variable public_subnet01_netnumber {
  type        = string
  description = "Private subenet"
}

variable cluster_name {
  type        = string
  description = "K8s cluster name"
}


