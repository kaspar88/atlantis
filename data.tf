 
data "aws_availability_zones" "available" {} 
data "aws_caller_identity" "current" {}

data "aws_iam_user" "kaspar" {
  user_name = "kaspar"
}

data "aws_iam_policy_document" "eks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.account_id]
    }
  }
}


data "aws_secretsmanager_secret" "github_token" {
  name = "atlantis"
}

data "aws_secretsmanager_secret_version" "github_token" {
  secret_id = data.aws_secretsmanager_secret.github_token.id
}
