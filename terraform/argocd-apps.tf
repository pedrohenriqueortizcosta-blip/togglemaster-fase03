# ---------------------------------------------------------------------------
# One ArgoCD Application per microservice, each watching its own
# gitops/<service> folder in this same repo. Auto-sync + self-heal means
# CI's image-tag-bump commits (the "update-gitops" job in each pipeline)
# propagate to the cluster with no manual step.
# ---------------------------------------------------------------------------
resource "kubernetes_manifest" "argocd_app" {
  for_each = toset(var.microservices)

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = each.value
      namespace = kubernetes_namespace.argocd.metadata[0].name
    }
    spec = {
      project = "default"

      source = {
        repoURL        = "https://github.com/${var.github_repository}.git"
        targetRevision = "main"
        path           = "gitops/${each.value}"
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = each.value
      }

      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=false"]
      }
    }
  }

  depends_on = [helm_release.argocd]
}
