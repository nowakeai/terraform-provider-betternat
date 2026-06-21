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
      version = "~> 0.1"
    }
  }
}

provider "betternat" {}
```

## OpenTofu

OpenTofu support is a release target, but it should only be claimed for releases that have been tested with `tofu init`, `tofu validate`, and provider install from a registry-compatible artifact.

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

Current validation status:

- Terraform `v1.15.6` local override validate passed on `darwin_arm64`.
- OpenTofu local override validation is pending because `tofu` was not installed in the first validation environment.
