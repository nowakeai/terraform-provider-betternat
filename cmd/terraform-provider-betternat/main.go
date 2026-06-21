package main

import (
	"context"
	"log"

	"github.com/hashicorp/terraform-plugin-framework/providerserver"

	"github.com/nowakeai/betternat/pkg/tfprovider"
	"github.com/nowakeai/terraform-provider-betternat/internal/buildinfo"
)

func main() {
	if err := providerserver.Serve(context.Background(), tfprovider.New(buildinfo.Version), providerserver.ServeOpts{
		Address: "registry.terraform.io/nowakeai/betternat",
	}); err != nil {
		log.Fatal(err)
	}
}
