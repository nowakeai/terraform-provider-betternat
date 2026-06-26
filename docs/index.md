# BetterNAT Provider

The BetterNAT provider deploys and manages self-hosted egress gateway node
stacks for BetterNAT modules and advanced Terraform users.

BetterNAT is aimed at workloads where NAT Gateway data-processing fees dominate the bill, such as crawler fleets, Kubernetes nodes that frequently pull large public images, and blockchain/RPC nodes that download high-volume public peer data.

## Example Usage

```terraform
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

OpenTofu can use the same `source = "nowakeai/betternat"` address because the
provider is registered in the OpenTofu Registry.

## Current Scope

Most users should install BetterNAT through a cloud module:

```terraform
module "betternat" {
  source = "nowakeai/betternat/aws"
}

module "betternat" {
  source = "nowakeai/betternat/google"
}
```

The provider resources are lower-level lifecycle primitives.

`betternat_aws_gateway` deploys the AWS gateway stack through the default
`bootstrap_mode = "cloud_init"` flow. Users provide an explicit Linux AMI and
`betternat_version`; the provider derives the gateway node binary URLs and
checksums for that runtime version.

Private prebaked BetterNAT AMIs can opt into
`bootstrap_mode = "prebaked_ami"`. In stable EIP mode, that path disables
per-node auto-assigned public IPv4 because the AMI already contains the runtime
and no first-boot dependency downloads are required.

`associate_public_ip_address` is available as an advanced launch-template
override when an environment needs to force the per-node public IPv4 setting.

`betternat_gcp_gateway` deploys the GCP gateway stack with Firestore-backed HA,
tagged route ownership, LoxiLB datapath bootstrap, optional stable public
identity through an existing regional static external IPv4 address, and
MIG-backed capacity repair when `capacity_repair_mode = "mig"`.

The provider also exposes `betternat_runtime_artifacts` for release artifact
metadata, `betternat_aws_gateway_status` for read-only AWS control-plane status
reads, and `betternat_gcp_gateway_status` for read-only GCP Compute status
reads.

LoxiLB is the supported BetterNAT datapath. BetterNAT does not expose nftables
fallback behavior as a product path.

Provider patch releases are intended to be non-breaking. They must not remove
Terraform fields, remove documented `betternat_version` support, introduce
incompatible state changes, or require replacement for unchanged
configuration.

## Authentication

The provider uses the default AWS credential chain through the AWS SDK. Typical options include:

- `AWS_PROFILE`
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`
- instance or workload identity when running inside AWS

## Provider Schema

### Optional

- `aws_endpoint_url` (String) Optional AWS-compatible endpoint URL for local testing, such as LocalStack. Leave unset for real AWS.

## OpenTofu Registry Status

OpenTofu can install this provider from the OpenTofu Registry with the same
source address:

```terraform
source = "nowakeai/betternat"
```
