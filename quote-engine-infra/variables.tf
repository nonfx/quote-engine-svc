variable "project_id" {
  description = "GCP project that hosts the quote-engine backend."
  type        = string
  default     = "quote-engine-demo"
}

variable "region" {
  description = "Primary region for regional resources."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Primary zone for zonal resources."
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Deployment environment label."
  type        = string
  default     = "demo"
}

variable "labels" {
  description = "Common labels applied to resources that support them."
  type        = map(string)
  default = {
    service = "quote-engine"
    team    = "platform"
  }
}
