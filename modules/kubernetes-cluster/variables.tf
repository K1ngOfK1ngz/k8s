variable key_name {
  type        = string
  default     = "rodel"
  description = "Key name pem for ssh"
}

variable ami {
  type        = string
  description = "AMI Image ID"
}

variable master_instance_type {
  type        = string
  default     = ""
  description = "Master Nodes instance type"
}
