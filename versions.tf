terraform {
  required_version = ">= 0.13.1"

  required_providers {
    gandi = {
      source   = "go-gandi/gandi"
      version = "~> 2.0.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}


