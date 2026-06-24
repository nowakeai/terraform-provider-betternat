# betternat_gateway

`betternat_gateway` deploys a BetterNAT gateway node pool for AWS egress.

Use this resource when you want private route tables to send internet-bound
traffic through a self-managed BetterNAT gateway node pool instead of an AWS NAT
Gateway. The provider creates the AWS support infrastructure, renders the
gateway node bootstrap configuration, records route rollback metadata, and
passes HA configuration to `betternat-agent`.

The first alpha is AWS-only and single-AZ per resource. To cover multiple AZs,
create one `betternat_gateway` resource per AZ and pass the public subnet and
private route tables for that AZ.

## What This Resource Manages

During create, the provider:

- creates the gateway node Auto Scaling Group and launch template,
- creates or records the DynamoDB coordination backend used by the agents,
- creates the IAM role, instance profile, and runtime IAM policy,
- optionally allocates and manages a shared EIP when `stable_egress_ip = true`,
- renders `/etc/betternat/agent.json` and cloud-init user data,
- records the previous private route targets for rollback,
- starts a gateway node pool where one node becomes active and the rest remain standby.

At runtime, `betternat-agent` on the gateway nodes owns the active/standby
decision. The active node owns the lease, reconciles the datapath, and updates
the private default route. Standby nodes keep registering their state and can
take over after lease expiry or proactive handover.

## Example Usage

```terraform
terraform {
  required_providers {
    betternat = {
      source  = "nowakeai/betternat"
      version = "= 0.1.0-alpha.6"
    }
  }
}

provider "betternat" {}

resource "betternat_gateway" "egress" {
  name   = "prod-egress-a"
  region = "us-west-2"
  vpc_id = aws_vpc.main.id

  public_subnet_ids = {
    us-west-2a = aws_subnet.public_a.id
  }

  private_route_table_ids = {
    us-west-2a = [
      aws_route_table.private_a.id,
      aws_route_table.private_workers_a.id,
    ]
  }

  private_cidrs = [aws_vpc.main.cidr_block]

  ami_id        = data.aws_ami.ubuntu_arm64.id
  instance_type = "t4g.small"
  use_spot      = false

  min_size         = 1
  desired_capacity = 2
  max_size         = 3

  betternat_version = "v0.1.0-alpha.2"
  bootstrap_mode    = "cloud_init"

  datapath_engine          = "loxilb"
  fallback_datapath_engine = "nftables"

  stable_egress_ip   = true
  ha_profile         = "default"
  prometheus_enabled = true

  rollback_on_destroy = true

  tags = {
    Service = "betternat"
  }
}
```

## Network Model

`public_subnet_ids` and `private_route_table_ids` are keyed by AZ name. Every
AZ listed in `private_route_table_ids` must have a matching public subnet entry.
For the current alpha, configure a single AZ per resource:

```terraform
public_subnet_ids = {
  us-west-2a = aws_subnet.public_a.id
}

private_route_table_ids = {
  us-west-2a = [aws_route_table.private_a.id]
}
```

The gateway nodes run in the public subnet. Workloads stay in private subnets.
The provider and agents manage the private route table destination configured by
`route_destination_cidr`, which defaults to `0.0.0.0/0`.

Do not manage the same private default route with a separate `aws_route`
resource. BetterNAT must be the only owner of that route while the resource is
active.

## Egress IP Modes

### Stable Egress IP

With `stable_egress_ip = true`, BetterNAT uses a shared EIP. On failover, the
new active node associates the shared EIP and updates the private route target.
Use this mode when downstream services allowlist your public source IP.

This mode keeps the public IP stable for new flows after failover. Existing
connections are not preserved.

With the default `bootstrap_mode = "cloud_init"`, gateway nodes also have
ordinary per-node public IPv4 addresses for bootstrap and
management/control-plane reachability. Treat those addresses as operational
reachability only; the shared EIP is the intended public source IP for
private-subnet egress in stable mode.

With `bootstrap_mode = "prebaked_ami"`, stable EIP deployments disable per-node
auto-assigned public IPv4 because the AMI already contains the BetterNAT runtime
and no first-boot package/image/artifact downloads are required.

Set `associate_public_ip_address` only when you deliberately want to override
the provider-derived public IPv4 behavior for the launch template.

### Non-Stable Egress IP

With `stable_egress_ip = false`, BetterNAT does not manage a shared EIP. The
active node uses its own public IP, and failover only needs to converge route
ownership. This can be faster, but the public source IP changes when another
node becomes active.

Use this mode only when destination allowlists and source-IP stability are not
required.

## Bootstrap And Artifacts

The default mode is `bootstrap_mode = "cloud_init"`. Use this for ordinary
Linux AMIs. The first alpha does not publish a BetterNAT AMI, so the public
quick-start path provides `ami_id` and sets `betternat_version` for bootstrap
installs.

The provider uses `betternat_version` and `instance_type` to derive the matching
Linux `arm64` or `amd64` GitHub Release artifacts and SHA256 checksums for
`betternat-agent` and the `betternat` CLI.

The explicit `agent_binary_url`, `agent_binary_sha256`, `cli_binary_url`, and
`cli_binary_sha256` fields remain available as advanced overrides for mirrored,
air-gapped, or unreleased test builds. Leave them empty for normal public
release installs.

`loxicmd_binary_url` is optional. If it is unset, bootstrap installs a Docker
wrapper for LoxiLB tooling.

Use `bootstrap_mode = "prebaked_ami"` only for BetterNAT AMIs that already
contain Docker or the selected LoxiLB runtime, LoxiLB, `betternat`,
`betternat-agent`, `loxicmd`, sysctl settings, and systemd units. In this mode,
user data only writes `/etc/betternat/agent.json`, reapplies the baseline sysctl
profile, starts `loxilb.service`, and restarts or enables
`betternat-agent.service`.

`prebaked_ami` rejects bootstrap artifact overrides such as `agent_binary_url`
or `cli_binary_url`; the runtime is part of the AMI. `betternat_version` may
still be recorded in configuration for operator clarity, but it is not used to
download artifacts in `prebaked_ami` mode.

Public IPv4 behavior:

| `bootstrap_mode` | `stable_egress_ip` | Auto-assigned public IPv4 |
| --- | --- | --- |
| `cloud_init` | `true` | Enabled for bootstrap and management/control-plane reachability. |
| `cloud_init` | `false` | Enabled; the active node public IP is the egress identity. |
| `prebaked_ami` | `true` | Disabled; the shared EIP is the egress identity. |
| `prebaked_ami` | `false` | Enabled; the active node public IP is the egress identity. |

`associate_public_ip_address` overrides the table above. For example, a private
VPC with NAT/VPC endpoints may set it to `false` even in `cloud_init` mode. A
troubleshooting environment may set it to `true` even for a prebaked stable-EIP
AMI.

### Runtime Support Matrix

| Provider version | Supported `betternat_version` values | Notes |
| --- | --- | --- |
| `0.1.0-alpha.6` | `v0.1.0-alpha.2` | First provider with built-in runtime artifact URL/checksum derivation. |

The provider fails with a clear error when `betternat_version` is unsupported.
Provider patch releases should not remove a documented runtime version from
this matrix.

## HA Lifecycle

The node pool is active/standby:

1. A node starts, registers itself in the coordination backend, and starts the
   local datapath.
2. One node acquires the HA lease and becomes active.
3. The active node owns route replacement and shared EIP association when
   enabled.
4. Standby nodes keep renewing their own registry data and monitoring the lease.
5. On active node failure, graceful shutdown, ASG lifecycle termination, Spot
   interruption, or manual handover, another node takes ownership.

`ha_profile = "default"` currently uses a 10 second lease TTL and 1 second
renew/check interval. The legacy values `stable`, `balanced`, and `fast` are
accepted as aliases for `default`.

Only set `ha_lease_ttl_seconds` and `ha_renew_interval_seconds` when you need an
explicit advanced timing override. Very short TTLs can reduce failover time but
increase sensitivity to transient AWS/DynamoDB/API latency.

## Update Lifecycle

Only capacity fields are intended to update in place in the current provider
version:

- `min_size`
- `desired_capacity`
- `max_size`

Changing topology, `bootstrap_mode`, `betternat_version`, bootstrap artifact
overrides, route ownership, datapath, EIP mode, HA timing, AMI, instance type,
subnet IDs, private CIDRs, or tags requires replacing the resource:

```shell
terraform apply -replace=betternat_gateway.egress
```

Provider upgrades may reconcile safe supporting resources in place, such as IAM
policy and coordination table metadata. The
`provider_infrastructure_revision` read-only field records the provider-owned
infrastructure revision used for that reconciliation.

Provider patch releases are intended to be non-breaking: no Terraform field
removal, incompatible state change, removal of supported runtime versions, or
new replacement requirement for unchanged configuration. Runtime patch releases
are also intended to preserve agent config, CLI, metrics, HA coordination, and
bootstrap compatibility for the same supported line.

## Destroy And Rollback Lifecycle

By default, `rollback_on_destroy = true`. The provider attempts to restore the
private route table targets captured before BetterNAT took ownership.

Destroy can fail if rollback is enabled but the provider does not have concrete
rollback targets in state. In that case, first manually restore or accept the
private route table state, then set:

```terraform
allow_destroy_without_rollback = true
```

Only use `allow_destroy_without_rollback` when you have confirmed the private
routes will not be left pointing at deleted gateway nodes.

## Operations After Apply

After the nodes are running, use the CLI from a gateway node:

```shell
sudo betternat status
sudo betternat doctor --live
sudo betternat handover status
sudo betternat handover history
```

When `prometheus_enabled = true`, each gateway node exposes metrics on port
`9108`.

## Required

- `name` (String) Gateway name. Used in AWS resource names, DynamoDB table names, tags, and HA group identity. Choose a stable name; changing it requires replacement.
- `region` (String) AWS region where the gateway stack is created.
- `vpc_id` (String) Target VPC ID. Public subnets, private route tables, and gateway nodes must belong to this VPC.
- `public_subnet_ids` (Map of String) Public subnet ID per availability zone. Keys are AZ names such as `us-west-2a`; values are subnet IDs where gateway nodes can run.
- `private_route_table_ids` (Map of List of String) Private route table IDs per availability zone. BetterNAT owns `route_destination_cidr` in these route tables.
- `private_cidrs` (List of String) Private CIDRs allowed to use the gateway for SNAT. Usually this is the VPC CIDR or narrower private workload CIDRs.

## Optional

- `cloud` (String) Cloud target. Defaults to `aws`. The first alpha only supports AWS.
- `ami_id` (String) Explicit Linux AMI ID for gateway nodes. Required for the first alpha bootstrap path because production BetterNAT AMIs are not published yet.
- `ami_channel` (String) Future AMI channel selector. Defaults to `stable`. Accepted values are `stable`, `candidate`, and `dev`, but the first alpha still requires `ami_id`.
- `instance_type` (String) Gateway node instance type. Defaults to `t3.small`. Use an instance family and architecture that match your binary artifacts.
- `use_spot` (Boolean) Use Spot instances for the gateway ASG. Defaults to `false`. Good for disposable testing; use carefully for real egress.
- `min_size` (Number) ASG minimum size. Defaults to `1`.
- `desired_capacity` (Number) ASG desired capacity. Defaults to `2`, giving one active node and one standby node.
- `max_size` (Number) ASG maximum size. Defaults to `3`.
- `betternat_version` (String) BetterNAT runtime release tag used to derive agent/CLI GitHub Release artifact URLs and checksums for bootstrap installs. Example: `v0.1.0-alpha.2`.
- `agent_binary_url` (String, Sensitive) Optional URL override for the BetterNAT agent binary installed on every gateway node.
- `agent_binary_sha256` (String) Optional SHA256 checksum override for `agent_binary_url`.
- `cli_binary_url` (String, Sensitive) Optional URL override for the BetterNAT CLI binary installed on every gateway node.
- `cli_binary_sha256` (String) Optional SHA256 checksum override for `cli_binary_url`.
- `loxicmd_binary_url` (String, Sensitive) Optional URL for a host `loxicmd` binary. If unset, bootstrap installs a Docker wrapper.
- `loxicmd_binary_sha256` (String) SHA256 checksum for `loxicmd_binary_url`.
- `datapath_engine` (String) Primary datapath. Defaults to `loxilb`. Accepted values are `loxilb` and `nftables`.
- `fallback_datapath_engine` (String) Fallback datapath. Defaults to `nftables`. Accepted values are empty string or `nftables`.
- `stable_egress_ip` (Boolean) Manage a shared EIP so new private-subnet egress flows converge back to the same public IP after failover. Gateway nodes may still have ordinary public IPv4 addresses for bootstrap and management. Defaults to `true`.
- `ha_profile` (String) HA timing profile. Use `default`. Legacy values `stable`, `balanced`, and `fast` are accepted as aliases for `default`.
- `ha_lease_ttl_seconds` (Number) Advanced override for HA lease TTL in seconds. Leave unset to use profile defaults.
- `ha_renew_interval_seconds` (Number) Advanced override for HA lease renew interval in seconds. Leave unset to use profile defaults.
- `prometheus_enabled` (Boolean) Expose Prometheus metrics from each gateway node. Defaults to `true`.
- `route_mode` (String) Route failover mode. Defaults to `replace_route`. The first alpha only supports `replace_route`.
- `route_destination_cidr` (String) Route destination managed by BetterNAT. Defaults to `0.0.0.0/0`.
- `route_target_type` (String) Route target type. Defaults to `instance`. The first alpha only supports EC2 instance route targets.
- `rollback_on_destroy` (Boolean) Attempt to restore captured route targets during destroy. Defaults to `true`.
- `allow_destroy_without_rollback` (Boolean) Allow destroy to continue when rollback cannot be performed. Defaults to `false`.
- `tags` (Map of String) Tags applied to managed AWS resources.

## Read-Only

- `id` (String) Resource ID.
- `lease_table_name` (String) DynamoDB lease table name. Kept for compatibility with earlier alpha state.
- `coordination_table_name` (String) DynamoDB coordination table name used for HA lease, agent registry, handover records, and future backend-mediated coordination records.
- `peer_api_auth_token` (String, Sensitive) Provider-generated shared token rendered into gateway node config for authenticated agent-to-agent handover API calls.
- `provider_infrastructure_revision` (String) Provider-managed infrastructure revision used for safe in-place reconciliation of supporting resources.
- `agent_config_json` (String, Sensitive) Rendered gateway node agent configuration.
- `agent_config_hash` (String) Hash of the rendered agent configuration.
- `user_data` (String, Sensitive) Rendered gateway node cloud-init user data.
- `install_plan_json` (String) Rendered install plan metadata.
- `managed_route_table_ids` (List of String) Flattened route table IDs managed by the gateway.
- `egress_public_ips` (Map of String) Observed egress public IPs by AZ or node role when available.
- `active_instance_ids` (Map of String) Active gateway node instance IDs per availability zone when observed.
- `standby_instance_ids` (Map of String) Standby gateway node instance IDs per availability zone when observed.
- `rollback_route_targets_json` (String) Captured rollback route targets used during destroy.
- `control_plane_status_json` (String) Control-plane status metadata observed by the provider.
- `status` (String) Resource status summary.
