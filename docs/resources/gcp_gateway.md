# betternat_gcp_gateway

`betternat_gcp_gateway` is an alpha resource for disposable GCP validation.

It manages provider-owned GCE gateway VMs with `canIpForward=true`, an nftables
masquerade startup script, and one tagged default route to the active gateway.

It does not yet provide BetterNAT agent lease coordination, LoxiLB-on-GCE
validation, stable public IP handover, production GKE route migration safety,
or production HA guarantees.

## Example Usage

```hcl
resource "betternat_gcp_gateway" "egress" {
  name       = "lab-egress"
  project_id = "shared-resources-alt"
  region     = "us-west1"
  zone       = "us-west1-a"

  network    = google_compute_network.lab.name
  subnetwork = google_compute_subnetwork.lab.name
  client_tag = "lab-private-client"

  private_cidrs = ["10.91.0.0/24"]
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
| `gateway_count` | `2` | Number of provider-owned gateway VMs. The initial route points at `gw-a`. |

## Computed

| Name | Description |
| --- | --- |
| `egress_public_ips` | Per-gateway public IPv4 addresses. |
| `gateway_statuses` | GCE instance status by gateway name. |
| `route_target` | Current route next-hop instance base name. |
| `startup_script` | Sensitive generated gateway startup script. |
| `status` | Provider status summary. |

## Update Behavior

Updates are intentionally not implemented in the first GCP alpha. Replace the
resource to change topology.
