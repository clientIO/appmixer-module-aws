terraform {
  required_version = ">= 1.6.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.32.1"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.1"
    }
  }
}
