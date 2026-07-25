locals {
  # Secure-by-default guest metadata. Caller-supplied metadata is merged last so
  # any individual key can still be overridden explicitly.
  #
  # enable-oslogin      - use IAM-managed SSH access instead of project/instance
  #                       metadata SSH keys, which are not centrally revocable.
  # serial-port-enable  - the interactive serial console bypasses the guest
  #                       firewall and OS Login, so keep it off unless asked for.
  metadata = merge(
    {
      "enable-oslogin"     = var.enable_oslogin ? "TRUE" : "FALSE"
      "serial-port-enable" = var.enable_serial_port ? "TRUE" : "FALSE"
    },
    var.metadata,
  )
}

resource "google_compute_instance_template" "this" {
  project      = var.project_id
  name_prefix  = var.name_prefix
  machine_type = var.machine_type
  region       = var.region
  tags         = var.tags
  metadata     = local.metadata
  labels       = var.labels

  disk {
    source_image = var.image
    disk_size_gb = var.disk_size_gb
    boot         = true
  }

  # No access_config block is emitted, so instances built from this template get
  # a private address only. An empty `access_config {}` would silently attach an
  # ephemeral external IP.
  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
  }

  # Secure Boot is OFF unless this block sets it, even on Shielded-VM-capable
  # images. Set var.shielded_instance_config to null for images without UEFI
  # support, where the API rejects the block outright.
  dynamic "shielded_instance_config" {
    for_each = var.shielded_instance_config == null ? [] : [var.shielded_instance_config]

    content {
      enable_secure_boot          = shielded_instance_config.value.enable_secure_boot
      enable_vtpm                 = shielded_instance_config.value.enable_vtpm
      enable_integrity_monitoring = shielded_instance_config.value.enable_integrity_monitoring
    }
  }

  # Instance templates are immutable: every change forces a new template. With
  # name_prefix + create_before_destroy the replacement is created first, so a
  # managed instance group referencing the old template can be repointed instead
  # of the destroy failing with "resource in use by another resource".
  lifecycle {
    create_before_destroy = true
  }
}
