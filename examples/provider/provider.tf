terraform {
  required_providers {
    betternat = {
      source  = "nowakeai/betternat"
      version = ">= 0.2.1"
    }
  }
}

provider "betternat" {}
