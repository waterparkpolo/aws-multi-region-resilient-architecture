############################################
# DNS Configuration
############################################

variable "zone_name" {
  description = "Private Route 53 hosted zone name"
  type        = string
}

variable "record_name" {
  description = "Application DNS record"
  type        = string
}