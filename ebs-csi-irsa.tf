resource "aws_iam_policy" "ebs_csi_driver" {
  name        = "${local.cluster_name}-AmazonEBSCSIDriverPolicy"
  description = "Policy required by Amazon EBS CSI driver"
  policy      = file("${path.module}/ebs-csi-policy.json") 
}

# IRSA Role for ebs-csi-controller-sa
module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.30.0"

  create_role                   = true
  role_name                     = "${local.cluster_name}-ebs-csi-controller"
  provider_url                  = module.eks.oidc_provider
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]

  role_policy_arns = [
    aws_iam_policy.ebs_csi_driver.arn
  ]
}
 
