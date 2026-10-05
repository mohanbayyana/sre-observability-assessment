variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "mohan-sre-assessment-20261001"
}

variable "region" {
  description = "Primary GCP region"
  type        = string
  default     = "us-east1"
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

variable "secondary_region" {
  description = "Region for the secondary GKE cluster"
  type        = string
  default     = "us-west1"
}

variable "secondary_subnet_cidr" {
  description = "CIDR range for the secondary GKE subnet"
  type        = string
  default     = "10.20.0.0/20"
}

variable "secondary_pods_cidr" {
  description = "Secondary IP range for secondary GKE pods"
  type        = string
  default     = "10.120.0.0/16"
}

variable "secondary_services_cidr" {
  description = "Secondary IP range for secondary GKE services"
  type        = string
  default     = "10.130.0.0/20"
}
