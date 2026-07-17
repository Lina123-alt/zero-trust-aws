variable "aws_region" {
  description = "La region AWS"
  type        = string
  default     = "eu-north-1"
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
  default     = "zero-trust-lab"
}

variable "vpc_cidr" {
  description = "Plage IP du reseau"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Plage IP public"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "Plage IP prive"
  type        = string
  default     = "10.0.2.0/24"
}

variable "allowed_ssh_ip" {
  description = "IP autorisee pour SSH"
  type        = string
  default     = "10.0.0.0/8"
}
