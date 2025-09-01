variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "myproject"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

# Database Configuration
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS (GB)"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for RDS (GB)"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "myproject_db"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "myproject"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# Redis Configuration
variable "redis_node_type" {
  description = "Redis node type"
  type        = string
  default     = "cache.t3.micro"
}

# Application Configuration
variable "app_cpu" {
  description = "CPU units for ECS task"
  type        = string
  default     = "256"
}

variable "app_memory" {
  description = "Memory for ECS task (MB)"
  type        = string
  default     = "512"
}

variable "app_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}