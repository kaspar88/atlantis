
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


data "aws_iam_policy_document" "atlantis_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.atlantis_oidc_issuer_host}"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.atlantis_oidc_issuer_host}:sub"
      values   = ["system:serviceaccount:atlantis:atlantis"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.atlantis_oidc_issuer_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "atlantis_irsa" {
  name               = "${local.cluster_name}-atlantis-irsa"
  assume_role_policy = data.aws_iam_policy_document.atlantis_assume_role.json
}


data "aws_iam_policy_document" "atlantis_backend" {
  statement {
    sid = "S3BackendBucket"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = [
      "arn:aws:s3:::kaspar-atlantis-terraform-state"
    ]
  }

  statement {
    sid = "S3BackendObjects"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      "arn:aws:s3:::kaspar-atlantis-terraform-state/*"
    ]
  }

  statement {
    sid = "DynamoDBLockTable"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:UpdateItem",
    ]
    resources = [
      "arn:aws:dynamodb:eu-north-1:${data.aws_caller_identity.current.account_id}:table/kaspar-atlantis-terraform"
    ]
  }

}

resource "aws_iam_policy" "atlantis_backend" {
  name   = "${local.cluster_name}-atlantis-backend"
  policy = data.aws_iam_policy_document.atlantis_backend.json
}

resource "aws_iam_role_policy_attachment" "atlantis_backend" {
  role       = aws_iam_role.atlantis_irsa.name
  policy_arn = aws_iam_policy.atlantis_backend.arn
}
