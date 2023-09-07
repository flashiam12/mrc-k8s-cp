terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.9.0"
    }
    dns = {
      source = "hashicorp/dns"
      version = "3.3.2"
    }
  }
}

provider "helm" {
  alias = "east-cluster-helm"
  kubernetes {
    host                   = module.k8s-east.cluster_endpoint
    cluster_ca_certificate = base64decode(module.k8s-east.cluster_ca_cert)
    token                  = module.k8s-east.cluster_auth_token
  }
}

provider "helm" {
  alias = "west-cluster-helm"
  kubernetes {
    host                   = module.k8s-west.cluster_endpoint
    cluster_ca_certificate = base64decode(module.k8s-west.cluster_ca_cert)
    token                  = module.k8s-west.cluster_auth_token
  }
}

provider "helm" {
  alias = "central-cluster-helm"
  kubernetes {
    host                   = module.k8s-central.cluster_endpoint
    cluster_ca_certificate = base64decode(module.k8s-central.cluster_ca_cert)
    token                  = module.k8s-central.cluster_auth_token
  }
}

provider "kubernetes" {
  alias = "east-cluster-kubernetes-raw"
  host                   = module.k8s-east.cluster_endpoint
  cluster_ca_certificate = base64decode(module.k8s-east.cluster_ca_cert)
  token                  = module.k8s-east.cluster_auth_token
}

provider "kubernetes" {
  alias = "west-cluster-kubernetes-raw"
  host                   = module.k8s-west.cluster_endpoint
  cluster_ca_certificate = base64decode(module.k8s-west.cluster_ca_cert)
  token                  = module.k8s-west.cluster_auth_token
}

provider "kubernetes" {
  alias = "central-cluster-kubernetes-raw"
  host                   = module.k8s-central.cluster_endpoint
  cluster_ca_certificate = base64decode(module.k8s-central.cluster_ca_cert)
  token                  = module.k8s-central.cluster_auth_token
}

provider "kubectl" {
  alias = "east-cluster-kubectl"
  host                   = module.k8s-east.cluster_endpoint
  cluster_ca_certificate = base64decode(module.k8s-east.cluster_ca_cert)
  token                  = module.k8s-east.cluster_auth_token
  load_config_file       = false
}

provider "kubectl" {
  alias = "west-cluster-kubectl"
  host                   = module.k8s-west.cluster_endpoint
  cluster_ca_certificate = base64decode(module.k8s-west.cluster_ca_cert)
  token                  = module.k8s-west.cluster_auth_token
  load_config_file       = false
}

provider "kubectl" {
  alias = "central-cluster-kubectl"
  host                   = module.k8s-central.cluster_endpoint
  cluster_ca_certificate = base64decode(module.k8s-central.cluster_ca_cert)
  token                  = module.k8s-central.cluster_auth_token
  load_config_file       = false
}

provider "aws" {
  alias = "aws-east"
  region = local.east.region
  access_key = var.aws_api_key
  secret_key = var.aws_api_secret
}

provider "aws" {
  alias = "aws-west"
  region = local.west.region
  access_key = var.aws_api_key
  secret_key = var.aws_api_secret
}

provider "aws" {
  alias = "aws-central"
  region = local.central.region
  access_key = var.aws_api_key
  secret_key = var.aws_api_secret
}

provider "dns" {

}