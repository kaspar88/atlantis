
############################
# EKS ADMIN ROLE
############################
resource "aws_iam_role" "eks_admin" {
  name               = "${local.cluster_name}-eks-admin-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role.json
}

resource "aws_iam_role_policy_attachment" "eks_admin_attach" {
  role       = aws_iam_role.eks_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

############################
# EKS READ-ONLY ROLE
############################
resource "aws_iam_role" "eks_readonly" {
  name               = "${local.cluster_name}-eks-readonly-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role.json
}

resource "aws_iam_role_policy_attachment" "eks_readonly_attach" {
  role       = aws_iam_role.eks_readonly.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSReadOnlyAccess"
} 
