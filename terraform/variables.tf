variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "mohan-sre-assessment-20261001"
}

variable "region" {
  description = "Primary GCP region"
  type        = string
  default     = "us-central1"
}

variable "subnet_cidr" {
  description = "CIDR range for GKE subnet"
  type        = string
  default     = "10.10.0.0/20"
}

variable "pods_cidr" {
  description = "Secondary IP range for GKE pods"
  type        = string
  default     = "10.100.0.0/16"
}

variable "services_cidr" {
  description = "Secondary IP range for GKE services"
  type        = string
  default     = "10.110.0.0/20"
}