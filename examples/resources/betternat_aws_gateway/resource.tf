terraform {
  required_providers {
    betternat = {
      source  = "nowakeai/betternat"
      version = ">= 0.2.0"
    }
  }
}

provider "betternat" {}

resource "betternat_aws_gateway" "egress" {
  name   = "test-egress"
  region = "us-west-2"
  vpc_id = "vpc-0123456789abcdef0"

  ami_id        = "ami-0123456789abcdef0"
  instance_type = "t4g.small"
  use_spot      = false

  min_size         = 1
  desired_capacity = 2
  max_size         = 3

  betternat_version = "v0.1.0"

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
