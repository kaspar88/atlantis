terraform {
  required_version = "~> 1.14.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.28.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.11.0"
    }
    dns = { 
      source = "hashicorp/dns"
      version = "~> 3.4" 
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10.0"
    }
  }
  backend "s3" {
    bucket               = "kaspar-atlantis-terraform"
    key                  = "remote_terraform.tfstate"
    region               = "eu-north-1"
    workspace_key_prefix = "environment" 
    acl                  = "private"
   dynamodb_table        = "kaspar-atlantis-terraform"
  }
}

provider "aws" {
  region                  = "eu-north-1"
}
