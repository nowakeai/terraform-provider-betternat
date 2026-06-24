# betternat_gateway

`betternat_gateway` deploys a BetterNAT gateway node pool for AWS egress.

The resource creates and manages the infrastructure needed by the alpha gateway stack, including gateway node capacity, bootstrap configuration, route ownership metadata, and HA control-plane configuration.

## Example Usage

```terraform
resource "betternat_gateway" "egress" {
  name   = "test-egress"
  region = "us-west-2"
  vpc_id = "vpc-0123456789abcdef0"

  ami_id        = "ami-0123456789abcdef0"
  instance_type = "t4g.small"
  use_spot      = false

  min_size         = 1
  desired_capacity = 2
  max_size         = 3

  agent_binary_url    = "https://github.com/nowakeai/betternat/releases/download/v0.1.0-alpha.2/betternat-agent_v0.1.0-alpha.2_linux_arm64"
  agent_binary_sha256 = "replace-with-agent-sha256"
  cli_binary_url      = "https://github.com/nowakeai/betternat/releases/download/v0.1.0-alpha.2/betternat_v0.1.0-alpha.2_linux_arm64"
  cli_binary_sha256   = "replace-with-cli-sha256"

  public_subnet_ids = {
    us-west-2a = "subnet-public-a"
  }

  private_route_table_ids = {
    us-west-2a = ["rtb-private-a"]
  }

  private_cidrs = ["10.0.0.0/8"]

  datapath_engine          = "loxilb"
  fallback_datapath_engine = "nftables"
  stable_egress_ip         = true
  ha_profile               = "default"
  prometheus_enabled       = true

  rollback_on_destroy = true

  tags = {
    Service = "betternat"
  }
}
```

## Bootstrap Notes

The first alpha does not publish a BetterNAT AMI. Use `ami_id` and explicit binary URLs/checksums for bootstrap installs.

If you use an ARM instance type such as `t4g.small`, use Linux `arm64` binary artifacts. If you use an x86_64 instance type such as `t3.small`, use Linux `amd64` binary artifacts.

## Update Behavior

Only capacity fields are intended to update in place in the current provider version:

- `min_size`
- `desired_capacity`
- `max_size`

Most topology, bootstrap, route, datapath, HA, and tag changes require replacing the resource, for example:

```shell
terraform apply -replace=betternat_gateway.egress
```

## Required

- `name` (String) Gateway name. Used in resource names and HA group identity.
- `region` (String) AWS region.
- `vpc_id` (String) Target VPC ID.
- `public_subnet_ids` (Map of String) Public subnet ID per availability zone.
- `private_route_table_ids` (Map of List of String) Private route table IDs per availability zone.
- `private_cidrs` (List of String) Private CIDRs allowed to use the gateway for SNAT.

## Optional

- `cloud` (String) Cloud target. Defaults to `aws`.
- `ami_id` (String) Explicit Linux AMI ID. Required for the first alpha bootstrap path.
- `ami_channel` (String) Future AMI channel selector. Defaults to `stable`.
- `instance_type` (String) Gateway node instance type. Defaults to `t3.small`.
- `use_spot` (Boolean) Use Spot instances. Defaults to `false`.
- `min_size` (Number) ASG minimum size.
- `desired_capacity` (Number) ASG desired capacity.
- `max_size` (Number) ASG maximum size.
- `agent_binary_url` (String, Sensitive) URL for the BetterNAT agent binary.
- `agent_binary_sha256` (String) SHA256 checksum for `agent_binary_url`.
- `cli_binary_url` (String, Sensitive) URL for the BetterNAT CLI binary.
- `cli_binary_sha256` (String) SHA256 checksum for `cli_binary_url`.
- `loxicmd_binary_url` (String, Sensitive) Optional URL for a host `loxicmd` binary. If unset, bootstrap installs a Docker wrapper.
- `loxicmd_binary_sha256` (String) SHA256 checksum for `loxicmd_binary_url`.
- `datapath_engine` (String) Primary datapath. Defaults to `loxilb`.
- `fallback_datapath_engine` (String) Fallback datapath. Defaults to `nftables`.
- `stable_egress_ip` (Boolean) Manage a shared EIP so new flows converge back to the same public IP after failover. Defaults to `true`.
- `ha_profile` (String) HA timing profile. Use `default`. Legacy values `stable`, `balanced`, and `fast` are accepted as aliases for `default`.
- `ha_lease_ttl_seconds` (Number) Advanced override for HA lease TTL in seconds.
- `ha_renew_interval_seconds` (Number) Advanced override for HA lease renew interval in seconds.
- `prometheus_enabled` (Boolean) Expose Prometheus metrics from each gateway node. Defaults to `true`.
- `route_mode` (String) Route failover mode. Defaults to `replace_route`.
- `route_destination_cidr` (String) Route destination managed by BetterNAT. Defaults to `0.0.0.0/0`.
- `route_target_type` (String) Route target type. Defaults to `instance`.
- `rollback_on_destroy` (Boolean) Attempt to restore captured route targets during destroy. Defaults to `true`.
- `allow_destroy_without_rollback` (Boolean) Allow destroy to continue when rollback cannot be performed. Defaults to `false`.
- `tags` (Map of String) Tags applied to managed resources.

## Read-Only

- `id` (String) Resource ID.
- `lease_table_name` (String) DynamoDB lease table name.
- `agent_config_json` (String, Sensitive) Rendered gateway node agent configuration.
- `agent_config_hash` (String) Hash of the rendered agent configuration.
- `user_data` (String, Sensitive) Rendered gateway node cloud-init user data.
- `install_plan_json` (String) Rendered install plan metadata.
- `managed_route_table_ids` (List of String) Route tables managed by the gateway.
- `egress_public_ips` (Map of String) Observed egress public IPs.
- `active_instance_ids` (Map of String) Active gateway node instance IDs per availability zone.
- `standby_instance_ids` (Map of String) Standby gateway node instance IDs per availability zone.
- `rollback_route_targets_json` (String) Captured rollback route targets.
- `control_plane_status_json` (String) Control-plane status metadata.
- `coordination_table_name` (String) DynamoDB coordination table name.
- `peer_api_auth_token` (String, Sensitive) Shared token for authenticated peer handover API calls.
- `provider_infrastructure_revision` (String) Provider-managed infrastructure revision used for safe in-place reconciliation.
- `status` (String) Resource status summary.
