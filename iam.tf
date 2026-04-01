
############################
# EKS ADMIN ROLE
############################
resource "aws_iam_role" "eks_admin" {
  name               = "${local.cluster_name}-eks-admin-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role.json
}

############################
# EKS READ-ONLY ROLE
############################
resource "aws_iam_role" "eks_readonly" {
  name               = "${local.cluster_name}-eks-readonly-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role.json
}
