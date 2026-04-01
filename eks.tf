
module "eks" {
  source                                   = "terraform-aws-modules/eks/aws"
  version                                  = "21.0.0"
  name                                     = local.cluster_name
  kubernetes_version                       = local.cluster_version
  endpoint_public_access                   = true
  endpoint_private_access                  = false
  enable_cluster_creator_admin_permissions = true
  subnet_ids                               = module.vpc.private_subnets
  vpc_id                                   = module.vpc.vpc_id
  enable_irsa                              = true

  authentication_mode              = "API_AND_CONFIG_MAP"

 access_entries = {
    kaspar = {
      principal_arn = data.aws_iam_user.kaspar.arn

      policy_associations = {
        admin = {
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }

    eks_admin_role = {
      principal_arn = aws_iam_role.eks_admin.arn

      policy_associations = {
        admin = {
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }

    eks_readonly_role = {
      principal_arn = aws_iam_role.eks_readonly.arn

      policy_associations = {
        readonly = {
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }

  
  addons = {
    aws-ebs-csi-driver = {
      version                     = "v1.46.0-eksbuild.1"
      service_account_role_arn = module.ebs_csi_irsa.iam_role_arn
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"

    }

    eks-pod-identity-agent = {
      before_compute = true
    }

    kube-proxy = {
      version                     = "v1.35.0-eksbuild.1"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }

    vpc-cni = {
      version                     = "v1.19.2-eksbuild.1"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      before_compute              = true
    }

    coredns = {
      version                     = "v1.12.0-eksbuild.1"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
  }



  eks_managed_node_groups = {

    workers = {
      name                               = "workers"
      use_name_prefix                    = true
      ami_type                           = "AL2023_x86_64_STANDARD"
      instance_types                     = [local.eks_node_type]
      min_size                           = local.eks_ng_min_size
      max_size                           = local.eks_ng_max_size
      desired_size                       = local.eks_ng_desired_size
      launch_template_name               = "workers"
      cluster_primary_security_group_id  = module.eks.cluster_primary_security_group_id
      vpc_security_group_ids             = [module.eks.node_security_group_id]

      iam_role_attach_cni_policy         = true

      labels = {
        node-group  = "workers"
      }

      block_device_mappings = {
        "/dev/xvda" = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = local.eks_ng_root_disk_size
            volume_type           = "gp3"
            delete_on_termination = true
          }
        }
      }

      update_config = {
        max_unavailable = 1
      }
    }
  }
} 
