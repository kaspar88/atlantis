locals {
  az_count                             = 2
  cluster_name                         = "kaspar-atlantis"
  cluster_cidr                         = "10.20.0.0/16"
  cluster_version                      = "1.35"
  region                               = "eu-north-1"

  private_subnets                      = [
    for i in range(local.az_count) :
    cidrsubnet(local.cluster_cidr, 8, i + 1)
  ]

  public_subnets = [
    for i in range(local.az_count) :
    cidrsubnet(local.cluster_cidr, 8, i + 4)
  ]

  eks_node_type                    = "t3.small"
  eks_ng_root_disk_size            = "20"
  eks_ng_min_size                  = "1"
  eks_ng_max_size                  = "2"
  eks_ng_desired_size              = "2"
  
  github_token = jsondecode(
    data.aws_secretsmanager_secret_version.github_token.secret_string
  ).ATLANTIS_GITHUB_TOKEN
  
  atlantis8_test = "ok"
}
  
