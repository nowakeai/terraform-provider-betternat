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
