terraform {
  required_providers {
    betternat = {
      source  = "nowakeai/betternat"
      version = "= 0.1.0-alpha.2"
    }
  }
}

provider "betternat" {}

resource "betternat_gateway" "egress" {
  name   = "prod-egress"
  region = "us-west-2"
  vpc_id = "vpc-0123456789abcdef0"

  ami_id        = "ami-0123456789abcdef0"
  instance_type = "t3.small"
  use_spot      = false

  min_size         = 1
  desired_capacity = 2
  max_size         = 3

  agent_binary_url    = "https://github.com/nowakeai/betternat/releases/download/v0.1.0-alpha.1/betternat-agent_v0.1.0-alpha.1_linux_amd64"
  agent_binary_sha256 = "replace-with-agent-sha256"
  cli_binary_url      = "https://github.com/nowakeai/betternat/releases/download/v0.1.0-alpha.1/betternat_v0.1.0-alpha.1_linux_amd64"
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
  ha_profile               = "stable"
  prometheus_enabled       = true

  rollback_on_destroy = true

  tags = {
    Service = "betternat"
  }
}
