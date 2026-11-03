variable "project_id" {
  description = "Project that holds Lab 1. No default - forces explicit input."
  type        = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "zone" {
  description = "Must match Lab 1's fs01 zone exactly."
  type        = string
  default     = "us-central1-a"
}

variable "instance_name" {
  description = "Must match Lab 1 exactly."
  type        = string
  default     = "fs01"
}

variable "tester_email" {
  description = "Your own Google account email. Receives permission to impersonate the three persona service accounts."
  type        = string
}

variable "operator_role_id" {
  description = "ID of the custom role. Change it if a previously deleted role with this ID blocks creation."
  type        = string
  default     = "fileServerOperator"
}
