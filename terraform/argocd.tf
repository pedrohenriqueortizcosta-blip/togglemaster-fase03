# ---------------------------------------------------------------------------
# ArgoCD: watches gitops/<service> in this repo and syncs it to the cluster.
#
# NOTE: the Application resources (argocd-apps.tf) reference the
# argoproj.io/v1alpha1 CRD this chart installs. On a completely fresh
# cluster, `kubernetes_manifest` needs that CRD to exist at PLAN time to
# validate the resource schema — so installing ArgoCD and creating
# Applications can't happen in the same `terraform apply` the very first
# time. Run `terraform apply` once to install ArgoCD, then again to create
# the Applications (every apply after that is a normal single pass).
# ---------------------------------------------------------------------------
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.7.3"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  # Defaults are fine for a single-cluster demo/coursework deployment —
  # no HA mode, no custom ingress (accessed via `kubectl port-forward`).
}
