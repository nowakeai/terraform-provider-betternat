terraform {
  required_providers {
    betternat = {
      source  = "nowakeai/betternat"
      version = ">= 0.2.0"
    }
  }
}

provider "betternat" {}

data "betternat_runtime_artifacts" "current" {
  version = "v0.1.0"
  os      = "linux"
  arch    = "arm64"
}

output "agent_binary_url" {
  value = data.betternat_runtime_artifacts.current.agent_binary_url
}
