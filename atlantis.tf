resource "random_password" "atlantis_webhook_secret" {
  length  = 40
  special = false
}

resource "kubernetes_namespace" "atlantis" {
  metadata {
    name = "atlantis"
  }

  depends_on = [module.eks]
}

resource "kubernetes_secret" "atlantis_vcs" {
  metadata {
    name      = "atlantis-vcs"
    namespace = kubernetes_namespace.atlantis.metadata[0].name
  }

  type = "Opaque"

  data = {
    github_user   = "atlantis-bot"
    github_token  = local.github_token
    github_secret = random_password.atlantis_webhook_secret.result
  }

  depends_on = [kubernetes_namespace.atlantis]
}

resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
  }

  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"

  parameters = {
    type      = "gp3"
    encrypted = "true"
  }
}

resource "helm_release" "atlantis" {
  name       = "atlantis"
  namespace  = kubernetes_namespace.atlantis.metadata[0].name
  repository = "https://runatlantis.github.io/helm-charts"
  chart      = "atlantis"

  timeout         = 900
  cleanup_on_fail = true

  values = [
    yamlencode({
      orgAllowlist = "github.com/kaspar88/*"

      vcsSecretName = kubernetes_secret.atlantis_vcs.metadata[0].name

      service = {
        type       = "LoadBalancer"
        port       = 80
        targetPort = 4141
      }

      ingress = {
        enabled = false
      }

      serviceAccount = {
        create = true
        name   = "atlantis"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.atlantis_irsa.arn
        }
      }

      github = {
        user = "atlantis-bot"
      }

      volumeClaim = {
        enabled          = true
        dataStorage      = "5Gi"
        storageClassName = "gp3"
      }

      resources = {
        requests = {
          cpu    = "100m"
          memory = "256Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }
    })
  ]

  depends_on = [
    module.eks,
    kubernetes_namespace.atlantis,
    kubernetes_secret.atlantis_vcs,
    kubernetes_storage_class_v1.gp3,
    aws_iam_role_policy_attachment.atlantis_backend
  ]
}

data "kubernetes_service" "atlantis" {
  metadata {
    name      = "atlantis"
    namespace = kubernetes_namespace.atlantis.metadata[0].name
  }

  depends_on = [helm_release.atlantis]
}

locals {
  atlantis_url = "http://${data.kubernetes_service.atlantis.status[0].load_balancer[0].ingress[0].hostname}"
}

resource "github_repository_webhook" "atlantis" {
  repository = "atlantis"

  active = true

  events = [
    "issue_comment",
    "pull_request",
    "pull_request_review",
    "push",
  ]

  configuration {
    url          = "${local.atlantis_url}/events"
    content_type = "json"
    insecure_ssl = false
    secret       = random_password.atlantis_webhook_secret.result
  }

  depends_on = [helm_release.atlantis]
}

output "atlantis_url" {
  value = local.atlantis_url
}

output "atlantis_ok" {
  value = local.atlantis_test
}
