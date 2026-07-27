############################################
# Database Configuration
############################################

variable "name" {
  description = "Name prefix for Aurora resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "database_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"
}

############################################
# Aurora Configuration
############################################

variable "engine" {
  description = "Aurora database engine"
  type        = string
  default     = "aurora-mysql"
}

variable "engine_version" {
  description = "Aurora engine version"
  type        = string
}

variable "instance_class" {
  description = "Aurora DB instance class"
  type        = string
}

############################################
# Global Database Configuration
############################################

variable "global_cluster_identifier" {
  description = "Aurora Global Database identifier"
  type        = string
}

############################################
# Networking
############################################

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 3306
}

############################################
# Tagging
############################################

variable "tags" {
  description = "Tags applied to all database resources"
  type        = map(string)
  default     = {}
}