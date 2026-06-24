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
      version = "= 0.1.0-alpha.5"
    }
  }
}

provider "betternat" {}
```

Registry documentation lives under [`docs/`](docs/) and resource examples under [`examples/`](examples/).

## OpenTofu

OpenTofu can install the provider from the OpenTofu Registry with the same
source address:

```hcl
terraform {
  required_providers {
    betternat = {
      source  = "nowakeai/betternat"
      version = "= 0.1.0-alpha.5"
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

- Terraform `v1.15.6` local override validate passed on `darwin_arm64`.
- OpenTofu `v1.12.3` local override validate passed on `darwin_arm64`.
- Terraform `v1.15.6` filesystem mirror install from provider release zip passed on `darwin_arm64`.
- OpenTofu `v1.12.3` filesystem mirror install from provider release zip passed on `darwin_arm64` when source explicitly used `registry.terraform.io/nowakeai/betternat`.
- OpenTofu Registry provider protocol lists `0.1.0-alpha.4` for darwin/arm64, linux/amd64, and linux/arm64.
- Terraform Registry install and validate passed for `nowakeai/betternat` `0.1.0-alpha.4`.

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
git tag v0.1.0-alpha.5
git push origin v0.1.0-alpha.5
```

The workflow uploads registry-compatible assets:

```text
terraform-provider-betternat_0.1.0-alpha.5_linux_amd64.zip
terraform-provider-betternat_0.1.0-alpha.5_linux_arm64.zip
terraform-provider-betternat_0.1.0-alpha.5_darwin_arm64.zip
terraform-provider-betternat_0.1.0-alpha.5_SHA256SUMS
terraform-provider-betternat_0.1.0-alpha.5_SHA256SUMS.sig
terraform-provider-betternat_0.1.0-alpha.5_manifest.json
```

The public key fingerprint currently registered with Terraform Registry is:

```text
3EA0C6EF878F7F50C75B3329F2D78A307FAB2914
```
