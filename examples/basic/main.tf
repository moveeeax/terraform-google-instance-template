terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Dedicated identity for the instances. Grant it only the roles the workload
# needs; the module does not fall back to the Compute Engine default SA.
resource "google_service_account" "this" {
  project      = var.project_id
  account_id   = "example-tpl"
  display_name = "Example instance template workload"
}

module "instance_template" {
  source = "../.."

  project_id   = var.project_id
  name_prefix  = "example-tpl-"
  region       = var.region
  machine_type = "e2-small"

  service_account = {
    email = google_service_account.this.email
  }

  labels = {
    environment = "sandbox"
  }
}

variable "project_id" {
  description = "Project ID to deploy the example instance template into."
  type        = string
}

variable "region" {
  description = "Region for the google provider and template."
  type        = string
  default     = "us-central1"
}

output "template_self_link" {
  value = module.instance_template.self_link
}
