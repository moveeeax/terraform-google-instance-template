variable "project_id" {
  description = "ID of the project in which to create the instance template."
  type        = string
}

variable "name_prefix" {
  description = "Prefix for the generated instance template name. Must be a valid start of a Compute Engine resource name and at most 37 characters, because the API appends a uniqueness suffix and truncates longer prefixes."
  type        = string

  validation {
    condition     = can(regex("^[a-z][-a-z0-9]*$", var.name_prefix))
    error_message = "name_prefix must start with a lowercase letter and contain only lowercase letters, digits and hyphens."
  }

  validation {
    # Compute Engine caps the generated name at 54 characters and silently
    # truncates prefixes longer than 37, which destroys the uniqueness the
    # suffix is meant to provide.
    condition     = length(var.name_prefix) <= 37
    error_message = "name_prefix must be 37 characters or fewer; longer prefixes are truncated by the API."
  }
}

variable "machine_type" {
  description = "Machine type for instances created from the template."
  type        = string
  default     = "e2-medium"
}

variable "region" {
  description = "Region in which to create the instance template."
  type        = string
}

variable "image" {
  description = "Boot disk source image for the template."
  type        = string
  default     = "debian-cloud/debian-12"
}

variable "disk_size_gb" {
  description = "Size of the boot disk in GB."
  type        = number
  default     = 20

  validation {
    condition     = var.disk_size_gb >= 10
    error_message = "disk_size_gb must be at least 10 GB."
  }
}

variable "network" {
  description = "Self link or name of the network to attach instances to."
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "Self link or name of the subnetwork to attach instances to."
  type        = string
  default     = null
}

variable "tags" {
  description = "Network tags applied to instances created from the template."
  type        = list(string)
  default     = []
}

variable "metadata" {
  description = "Metadata key/value pairs made available to instances."
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Labels applied to the instance template."
  type        = map(string)
  default     = {}
}

variable "enable_oslogin" {
  description = "Manage SSH access with OS Login (IAM) rather than metadata SSH keys. Set to false only if you rely on project or instance metadata SSH keys."
  type        = bool
  default     = true
}

variable "enable_serial_port" {
  description = "Allow interactive serial console access to instances created from the template. The serial console bypasses the guest firewall and OS Login, so it is disabled by default."
  type        = bool
  default     = false
}

variable "shielded_instance_config" {
  description = "Shielded VM settings for instances created from the template. Secure Boot is off unless enabled here. Set to null to omit the block entirely, which is required for boot images without UEFI support."
  type = object({
    enable_secure_boot          = optional(bool, true)
    enable_vtpm                 = optional(bool, true)
    enable_integrity_monitoring = optional(bool, true)
  })
  default = {}
}
