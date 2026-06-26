terraform {
  required_providers {
    betternat = {
      source  = "nowakeai/betternat"
      version = ">= 0.2.0"
    }
  }
}

provider "betternat" {}
