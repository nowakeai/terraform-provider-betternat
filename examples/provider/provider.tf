terraform {
  required_providers {
    betternat = {
      source  = "nowakeai/betternat"
      version = "= 0.1.0-alpha.2"
    }
  }
}

provider "betternat" {}
