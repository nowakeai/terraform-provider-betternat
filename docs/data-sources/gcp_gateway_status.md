# betternat_gcp_gateway_status

Reads current GCP Compute state for a BetterNAT GCP alpha gateway without
modifying cloud resources.

```hcl
data "betternat_gcp_gateway_status" "egress" {
  name       = betternat_gcp_gateway.egress.name
  project_id = betternat_gcp_gateway.egress.project_id
  region     = betternat_gcp_gateway.egress.region
  zone       = betternat_gcp_gateway.egress.zone
  network    = betternat_gcp_gateway.egress.network
  subnetwork = betternat_gcp_gateway.egress.subnetwork
  client_tag = betternat_gcp_gateway.egress.client_tag
  route_name = betternat_gcp_gateway.egress.route_name
}
```

## Inputs

| Name | Description |
| --- | --- |
| `name` | BetterNAT GCP alpha gateway base name. |
| `project_id` | GCP project ID. |
| `region` | GCP region. |
| `zone` | GCP zone containing provider-owned gateway VMs. |
| `network` | Existing VPC network name. |
| `subnetwork` | Existing regional subnetwork name. |
| `client_tag` | GCE network tag used by private clients. |
| `route_name` | Optional route name. Defaults to `<name>-default-via-gateway`. |
| `gateway_count` | Optional expected provider-owned gateway count. Defaults to `2`. |

## Outputs

| Name | Description |
| --- | --- |
| `gateway_statuses` | GCE instance status by provider-owned gateway instance name. |
| `egress_public_ips` | Per-gateway public IPv4 addresses. Stable public identity checks are handled by gateway-local status and GCP address ownership. |
| `route_target` | Current route next-hop instance base name. |
| `status` | Best-effort summary: `active` when gateway instances and route target are present, otherwise `missing`. |

This data source reports GCP Compute state only. It does not replace
gateway-local `betternat status`, `betternat doctor --live`, Prometheus
metrics, or Firestore handover history for runtime HA checks.
