provider "ncloud" {
  # access_key  = "1dAdLd2XAmdtCwoHE9BJ"
  # secret_key  = "85SaTVm1yuhMAaH5MJADXU5cy9PafzSBfRCbKRpq"
  region      = "KR"
  site        = "pub"
  support_vpc = "true"
}

provider "kubernetes" {
  host                   = data.ncloud_nks_kube_config.kube_config.host
  cluster_ca_certificate = base64decode(data.ncloud_nks_kube_config.kube_config.cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["token", "--clusterUuid", ncloud_nks_cluster.terraform_cluster.uuid, "--region", "KR"]
    command     = "ncp-iam-authenticator"
  }
}

## Terraform 설정
terraform {
  required_providers {
    ncloud = {
      source  = "NaverCloudPlatform/ncloud"
      version = ">= 2.3.19"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.24.0"
    }
  }
}

