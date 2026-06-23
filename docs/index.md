# BetterNAT Provider

The BetterNAT provider deploys and manages a self-hosted NAT gateway appliance stack for AWS.

BetterNAT is aimed at workloads where NAT Gateway data-processing fees dominate the bill, such as crawler fleets, Kubernetes nodes that frequently pull large public images, and blockchain/RPC nodes that download high-volume public peer data.

## Example Usage

```terraform
terraform {
  required_providers {
    betternat = {
      source  = "nowakeai/betternat"
      version = "= 0.1.0-alpha.3"
    }
  }
}

provider "betternat" {}
```

For OpenTofu, use the explicit Terraform Registry hostname until the OpenTofu-native registry entry is approved:

```terraform
terraform {
  required_providers {
    betternat = {
      source  = "registry.terraform.io/nowakeai/betternat"
      version = "= 0.1.0-alpha.3"
    }
  }
}

provider "betternat" {}
```

## Current Alpha Scope

`0.1.0-alpha.3` is a technical preview of the provider distribution path.

The provider currently deploys the `betternat_gateway` resource through a bootstrap flow. BetterNAT does not publish a production AMI in the first alpha, so users must provide an explicit Linux AMI and release artifact URLs/checksums for the appliance binaries.

## Authentication

The provider uses the default AWS credential chain through the AWS SDK. Typical options include:

- `AWS_PROFILE`
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`
- instance or workload identity when running inside AWS

## Provider Schema

### Optional

- `aws_endpoint_url` (String) Optional AWS-compatible endpoint URL for local testing, such as LocalStack. Leave unset for real AWS.

## OpenTofu Registry Status

OpenTofu can install this provider from the Terraform Registry when the source address is explicit. OpenTofu-native registry publication is tracked in:

- https://github.com/opentofu/registry/issues/4494
- https://github.com/opentofu/registry/issues/4496
