# betternat_gcp_gateway

`betternat_gcp_gateway` manages a BetterNAT GCP gateway group.

Most users should prefer the GCP module:

```hcl
module "betternat" {
  source  = "nowakeai/betternat/google"
  version = "~> 0.2"
}
```

The resource manages provider-owned GCE gateway VMs or a zonal MIG,
`canIpForward=true`, LoxiLB bootstrap, Firestore-backed HA, a tagged default
route, and optional stable public identity through an existing regional static
external IPv4 address.

## Example Usage

```hcl
resource "betternat_gcp_gateway" "egress" {
  name       = "prod-egress"
  project_id = var.project_id
  region     = "us-west2"
  zone       = "us-west2-a"

  network    = google_compute_network.main.name
  subnetwork = google_compute_subnetwork.private.name
  client_tag = "private-egress-client"

  private_cidrs = ["10.10.0.0/16"]

  enable_agent_ha       = true
  capacity_repair_mode  = "mig"
  betternat_version     = "v0.2.1"
  firestore_database_id = "(default)"

  manage_runtime_service_account = true
  manage_runtime_iam             = true
}
```

Private client VMs must carry `client_tag`. The resource does not create the
VPC, subnet, firewall rules, or client workloads.

## Required

| Name | Description |
| --- | --- |
| `name` | Base name for provider-owned gateway instances. |
| `project_id` | GCP project ID. |
| `region` | GCP region. |
| `zone` | GCP zone for gateway VMs. |
| `network` | Existing VPC network name. |
| `subnetwork` | Existing regional subnetwork name. |
| `client_tag` | GCE network tag whose traffic should use the BetterNAT route. |
| `private_cidrs` | Private CIDR ranges to masquerade on gateway instances. |

## Optional

| Name | Default | Description |
| --- | --- | --- |
| `route_name` | `<name>-default-via-gateway` | Provider-owned route name. |
| `route_priority` | `800` | GCP route priority. Must beat the default internet-gateway route for tagged clients. |
| `route_destination_cidr` | `0.0.0.0/0` | Destination CIDR for the managed route. |
| `machine_type` | `e2-small` | GCE gateway VM machine type. |
| `image_project` | `debian-cloud` | Image project for gateway boot disks. |
| `image_family` | `debian-12` | Image family for gateway boot disks. |
| `gateway_count` | `2` | Number of gateway VMs. |
| `capacity_repair_mode` | `unmanaged` | `mig` creates a zonal Managed Instance Group; modules use this for the GA path. |
| `enable_agent_ha` | `false` | Enables Firestore-backed BetterNAT agent HA. |
| `betternat_version` | none | BetterNAT runtime release tag for HA bootstrap artifacts. |
| `firestore_database_id` | `(default)` | Firestore Native database for HA coordination. |
| `manage_runtime_service_account` | `false` | Create/delete the runtime service account. |
| `manage_runtime_iam` | `false` | Create/update the runtime custom role and binding. |
| `stable_public_identity_address_name` | none | Existing regional static external IPv4 address name for stable public identity. |

## Computed

| Name | Description |
| --- | --- |
| `egress_public_ips` | Per-gateway public IPv4 addresses. |
| `gateway_statuses` | GCE instance status by gateway name. |
| `route_target` | Current route next-hop instance base name. |
| `startup_script` | Sensitive generated gateway startup script. |
| `status` | Provider status summary. |
| `runtime_iam_permissions` | Permissions required by the GCP runtime service account. |

## Stable Public Identity

Set `stable_public_identity_address_name` to an existing regional static
external IPv4 address name when private workloads need a stable egress identity.
The provider does not create or delete that address.

GCP handover is connectivity-first: BetterNAT moves the private workload route
first, then converges the static public identity. During that transition,
successful new connections may temporarily use the target gateway's ordinary
public IP before the static IP returns.

## Update Behavior

Updates are intentionally not implemented in the first GCP release. Replace the
resource to change topology.
