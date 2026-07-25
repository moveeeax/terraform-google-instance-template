# Requires Terraform >= 1.7 for `mock_provider`. The module itself still only
# requires >= 1.5; this is a test-only requirement and must not be promoted into
# versions.tf, which would break consumers on older CLIs.
#
# Runs entirely offline against a mocked google provider: no credentials, no API
# calls.

mock_provider "google" {}

variables {
  project_id  = "test-project"
  name_prefix = "test-tpl-"
  region      = "us-central1"
}

run "no_external_ip_by_default" {
  assert {
    condition     = length(google_compute_instance_template.this.network_interface[0].access_config) == 0
    error_message = "The template must not declare an access_config; an empty block assigns an ephemeral public IP to every instance."
  }
}

run "no_service_account_attached_by_default" {
  assert {
    condition     = length(google_compute_instance_template.this.service_account) == 0
    error_message = "The template must not attach a service account by default; doing so would hand instances the Compute Engine default SA."
  }
}

run "shielded_vm_hardened_by_default" {
  assert {
    condition     = length(google_compute_instance_template.this.shielded_instance_config) == 1
    error_message = "A shielded_instance_config block must be emitted by default."
  }

  assert {
    condition     = google_compute_instance_template.this.shielded_instance_config[0].enable_secure_boot
    error_message = "Secure Boot must be enabled by default; it is off whenever the block omits it."
  }

  assert {
    condition     = google_compute_instance_template.this.shielded_instance_config[0].enable_vtpm
    error_message = "vTPM must be enabled by default."
  }

  assert {
    condition     = google_compute_instance_template.this.shielded_instance_config[0].enable_integrity_monitoring
    error_message = "Integrity monitoring must be enabled by default."
  }
}

run "shielded_config_can_be_omitted_for_non_uefi_images" {
  variables {
    shielded_instance_config = null
  }

  assert {
    condition     = length(google_compute_instance_template.this.shielded_instance_config) == 0
    error_message = "Setting shielded_instance_config to null must omit the block, which images without UEFI support require."
  }
}

run "oslogin_on_and_serial_console_off_by_default" {
  assert {
    condition     = google_compute_instance_template.this.metadata["enable-oslogin"] == "TRUE"
    error_message = "OS Login must be enabled by default so SSH access is governed by IAM rather than metadata keys."
  }

  assert {
    condition     = google_compute_instance_template.this.metadata["serial-port-enable"] == "FALSE"
    error_message = "Interactive serial console access must be disabled by default."
  }
}

run "caller_metadata_is_preserved_and_can_override_defaults" {
  variables {
    metadata = {
      "app"            = "web"
      "enable-oslogin" = "FALSE"
    }
  }

  assert {
    condition     = google_compute_instance_template.this.metadata["app"] == "web"
    error_message = "Caller-supplied metadata keys must survive the merge with the secure defaults."
  }

  assert {
    condition     = google_compute_instance_template.this.metadata["enable-oslogin"] == "FALSE"
    error_message = "An explicit metadata key must win over the module default."
  }

  assert {
    condition     = google_compute_instance_template.this.metadata["serial-port-enable"] == "FALSE"
    error_message = "Untouched secure defaults must still be applied alongside caller metadata."
  }
}

run "toggles_are_honoured" {
  variables {
    enable_oslogin     = false
    enable_serial_port = true
  }

  assert {
    condition     = google_compute_instance_template.this.metadata["enable-oslogin"] == "FALSE"
    error_message = "enable_oslogin = false must render enable-oslogin = FALSE."
  }

  assert {
    condition     = google_compute_instance_template.this.metadata["serial-port-enable"] == "TRUE"
    error_message = "enable_serial_port = true must render serial-port-enable = TRUE."
  }
}

run "name_prefix_is_used_so_replacements_are_created_before_destroy" {
  assert {
    condition     = google_compute_instance_template.this.name_prefix == "test-tpl-"
    error_message = "The module must set name_prefix rather than name; instance templates are immutable and a fixed name cannot be replaced while a MIG references it."
  }
}

run "rejects_invalid_name_prefix_characters" {
  # Variable validation fails at plan time, so this run must not attempt an apply.
  command = plan

  variables {
    name_prefix = "Web_Tier-"
  }

  expect_failures = [var.name_prefix]
}

run "rejects_over_long_name_prefix" {
  # Variable validation fails at plan time, so this run must not attempt an apply.
  command = plan

  variables {
    name_prefix = "a-very-long-instance-template-name-prefix-that-will-be-truncated-"
  }

  expect_failures = [var.name_prefix]
}

run "rejects_undersized_boot_disk" {
  # Variable validation fails at plan time, so this run must not attempt an apply.
  command = plan

  variables {
    disk_size_gb = 5
  }

  expect_failures = [var.disk_size_gb]
}
