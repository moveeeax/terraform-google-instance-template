# terraform-google-instance-template

Terraform module that manages a [Google Cloud](https://cloud.google.com/)
Compute Engine instance template (`google_compute_instance_template`). Templates
define the boot disk, machine type and network interface used by managed
instance groups.

## Usage

```hcl
module "instance_template" {
  source = "github.com/moveeeax/terraform-google-instance-template"

  project_id   = var.project_id
  name_prefix  = "web-"
  region       = "us-central1"
  machine_type = "e2-medium"
  image        = "debian-cloud/debian-12"
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Defaults

The module is opinionated about the settings that are unsafe when left unset:

| Behaviour                     | Default                       | Why                                                                                                                                    |
|-------------------------------|-------------------------------|----------------------------------------------------------------------------------------------------------------------------------------|
| External IP                   | none                          | No `access_config` block is emitted. An empty `access_config {}` attaches an ephemeral public IP to every instance in the group.        |
| Service account               | none attached                 | Set one explicitly on the consuming resource rather than inheriting the Compute Engine default SA with the `cloud-platform` scope.      |
| Shielded VM                   | Secure Boot, vTPM and integrity monitoring all on | Secure Boot is **off** unless a `shielded_instance_config` block enables it, even on Shielded-VM-capable images.  |
| SSH access                    | OS Login (`enable-oslogin = TRUE`) | IAM-governed and centrally revocable, unlike metadata SSH keys.                                                                  |
| Interactive serial console    | disabled (`serial-port-enable = FALSE`) | The serial console bypasses the guest firewall and OS Login.                                                               |
| Template replacement          | `name_prefix` + `create_before_destroy` | Templates are immutable, so any change forces a new one. Without this the destroy fails with "resource in use by another resource" while a MIG still references the old template. |

Boot disks are encrypted at rest by Google-managed keys with no configuration
required; the module does not currently expose CMEK.

For boot images without UEFI support the API rejects `shielded_instance_config`
outright — set `shielded_instance_config = null` in that case.

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| google    | >= 5.0   |

## Inputs

| Name                       | Description                                                                                             | Type           | Default                    | Required |
|----------------------------|---------------------------------------------------------------------------------------------------------|----------------|----------------------------|:--------:|
| `project_id`               | ID of the project in which to create the template.                                                      | `string`       | n/a                        |   yes    |
| `name_prefix`              | Prefix for the generated template name. Max 37 chars; lowercase letters, digits and hyphens.            | `string`       | n/a                        |   yes    |
| `machine_type`             | Machine type for instances created from the template.                                                   | `string`       | `"e2-medium"`              |    no    |
| `region`                   | Region in which to create the instance template.                                                        | `string`       | n/a                        |   yes    |
| `image`                    | Boot disk source image for the template.                                                                | `string`       | `"debian-cloud/debian-12"` |    no    |
| `disk_size_gb`             | Size of the boot disk in GB. Must be >= 10.                                                             | `number`       | `20`                       |    no    |
| `network`                  | Self link or name of the network.                                                                       | `string`       | `"default"`                |    no    |
| `subnetwork`               | Self link or name of the subnetwork.                                                                    | `string`       | `null`                     |    no    |
| `tags`                     | Network tags applied to instances.                                                                      | `list(string)` | `[]`                       |    no    |
| `metadata`                 | Metadata key/value pairs. Merged over the module's secure defaults, so individual keys can be overridden. | `map(string)` | `{}`                       |    no    |
| `labels`                   | Labels applied to the instance template.                                                                | `map(string)`  | `{}`                       |    no    |
| `enable_oslogin`           | Manage SSH access with OS Login rather than metadata SSH keys.                                          | `bool`         | `true`                     |    no    |
| `enable_serial_port`       | Allow interactive serial console access.                                                                | `bool`         | `false`                    |    no    |
| `shielded_instance_config` | Shielded VM settings (`enable_secure_boot`, `enable_vtpm`, `enable_integrity_monitoring`). `null` omits the block. | `object`       | all `true`         |    no    |

## Outputs

| Name        | Description                             |
|-------------|-----------------------------------------|
| `id`        | Identifier of the instance template.   |
| `self_link` | URI of the instance template.          |
| `name`      | Generated name of the instance template.|

## Tests

`tests/` holds a `terraform test` suite that pins the defaults above. It uses a
mocked google provider, so it needs no credentials and makes no API calls:

```sh
terraform init -backend=false
terraform test
```

`mock_provider` requires Terraform/OpenTofu >= 1.7 for the tests only; the module
itself still supports >= 1.5.

## License

[MIT](LICENSE)
