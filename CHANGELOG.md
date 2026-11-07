# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- `service_account` input (`email`, `scopes` defaulting to `["cloud-platform"]`)
  that attaches a service account to instances built from the template. The
  default `null` keeps the current behaviour of attaching none. Validation
  rejects anything that is not a full email address, including the API's
  `default` alias for the Compute Engine default service account.
- `service_account_email` output.

### Changed

- CI: bump actions to their current majors, pin tool versions, and restrict the
  workflow token to `contents: read`.
- CI: add Dependabot for GitHub Actions and the Terraform provider.
- Docs: pin the README usage `source` to a release tag; fix the LICENSE year.

## [1.0.0]

Initial release (`v0.1.0` points at the same commit).

[Unreleased]: https://github.com/moveeeax/terraform-google-instance-template/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/moveeeax/terraform-google-instance-template/releases/tag/v1.0.0
