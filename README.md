# terraform-provider-betternat

Terraform and OpenTofu provider entrypoint for BetterNAT.

The provider implementation is intentionally thin. It imports the product-owned provider factory from:

```text
github.com/nowakeai/betternat/pkg/tfprovider
```

This keeps AWS install, bootstrap, HA, rollback, and validation logic in the main BetterNAT repository while giving Terraform/OpenTofu a registry-compatible provider repository name.

## Terraform Usage

```hcl
terraform {
  required_providers {
    betternat = {
      source  = "nowakeai/betternat"
      version = ">= 0.2.0"
    }
  }
}

provider "betternat" {}
```

Registry documentation lives under [`docs/`](docs/) and resource examples under
[`examples/`](examples/). The AWS and GCP modules are the recommended user
install surfaces; provider resources are lower-level primitives for module
authors and advanced validation.

## OpenTofu

OpenTofu can install the provider from the OpenTofu Registry with the same
source address:

```hcl
terraform {
  required_providers {
    betternat = {
      source  = "nowakeai/betternat"
      version = ">= 0.2.0"
    }
  }
}
```

The provider is also published through the Terraform Registry for Terraform CLI.

## Development

Build locally:

```sh
go build ./cmd/terraform-provider-betternat
```

Run tests:

```sh
go test ./...
```

For local provider development, configure a Terraform/OpenTofu provider override to point at the built `terraform-provider-betternat` binary.

Terraform local override smoke test:

```sh
go build ./cmd/terraform-provider-betternat

TF_CLI_CONFIG_FILE=$PWD/examples/local-override/terraform-dev.tfrc.example \
TMPDIR=/tmp \
terraform -chdir=examples/local-override validate
```

Update `terraform-dev.tfrc.example` to use the absolute path to this repository before running the command.

OpenTofu local override smoke test:

```sh
TF_CLI_CONFIG_FILE=$PWD/examples/local-override/terraform-dev.tfrc.example \
TMPDIR=/tmp \
tofu -chdir=examples/local-override validate
```

Current validation status:

- Provider surface reset validation passed with local dev overrides before
  publication.
- Terraform `v1.14.7` local dev override validate passed for
  `examples/local-override`, `examples/provider`, and
  `examples/resources/betternat_aws_gateway` on `linux/amd64`.
- BetterNAT runtime `v0.2.0` release artifacts and checksums are the intended
  normal `bootstrap_mode = "cloud_init"` install path once the runtime release
  artifacts are published and added to the provider manifest.
- Terraform Registry is the primary install path. OpenTofu can use the same
  provider source address through the OpenTofu Registry.

OpenTofu source address note:

```hcl
terraform {
  required_providers {
    betternat = {
      source  = "nowakeai/betternat"
      version = "~> 0.1"
    }
  }
}
```

The explicit `registry.terraform.io/nowakeai/betternat` source remains useful
only when intentionally testing Terraform Registry compatibility from OpenTofu.

## Release

The release workflow is designed for Terraform Registry ingestion.

Required repository secrets:

- `GPG_PRIVATE_KEY`: ASCII-armored private key for the Terraform Registry signing key.
- `GPG_PASSPHRASE`: passphrase for the signing key.

Tags must be v-prefixed semver tags, for example:

```sh
git tag v0.2.0
git push origin v0.2.0
```

The workflow uploads registry-compatible assets:

```text
terraform-provider-betternat_0.2.0_linux_amd64.zip
terraform-provider-betternat_0.2.0_linux_arm64.zip
terraform-provider-betternat_0.2.0_darwin_arm64.zip
terraform-provider-betternat_0.2.0_SHA256SUMS
terraform-provider-betternat_0.2.0_SHA256SUMS.sig
terraform-provider-betternat_0.2.0_manifest.json
```

The public key fingerprint currently registered with Terraform Registry is:

```text
3EA0C6EF878F7F50C75B3329F2D78A307FAB2914
```
