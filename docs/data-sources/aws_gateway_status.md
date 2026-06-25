# betternat_aws_gateway_status

`betternat_aws_gateway_status` reads current AWS control-plane state for an
existing BetterNAT gateway without modifying cloud resources.

## Example Usage

```terraform
data "betternat_aws_gateway_status" "egress" {
  name              = betternat_aws_gateway.egress.name
  region            = betternat_aws_gateway.egress.region
  install_plan_json = betternat_aws_gateway.egress.install_plan_json
}
```

Current status reads require `install_plan_json` from `betternat_aws_gateway`.
That keeps the data source explicit: it uses the exact route table, EIP, and
coordination table names the provider generated, instead of guessing from cloud
resource naming conventions.

## Schema

### Required

- `name` (String) BetterNAT gateway name.
- `region` (String) AWS region.
- `install_plan_json` (String, Sensitive) Install plan JSON from
  `betternat_aws_gateway.install_plan_json`.

### Read-Only

- `egress_public_ips` (Map of String) Current public egress IPs by availability
  zone when stable public identity is enabled.
- `route_targets` (Map of String) Current managed default-route targets by route
  table ID.
- `active_instance_ids` (Map of String) Current public-identity owner instance
  IDs by availability zone when available.
- `coordination_table_name` (String) Provider-owned DynamoDB coordination table
  name from the install plan.
- `control_plane_status_json` (String) Raw JSON status returned by the AWS
  reader.
- `status` (String) Best-effort summary: `active`, `degraded`, or `created`.
