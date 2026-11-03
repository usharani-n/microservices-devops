variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project_name" {
  type    = string
  default = "microservices-devops"
}

variable "instance_type" {
  description = "EC2 size. t3.small (2 GB) fits the 3 services, Mongo, RabbitMQ, Nginx and monitoring."
  type        = string
  default     = "t3.small"
}

variable "admin_cidr" {
  description = "Your public IP in CIDR form, e.g. 203.0.113.10/32. Only this address can SSH."
  type        = string
}

variable "public_key_path" {
  type    = string
  default = "~/.ssh/devops-ec2.pub"
}

variable "ecr_repositories" {
  type    = list(string)
  default = ["user-service", "product-service", "order-service"]
}
