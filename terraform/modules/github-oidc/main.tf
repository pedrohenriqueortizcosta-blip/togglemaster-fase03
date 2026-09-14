# GitHub's OIDC provider thumbprint is well-known/static; AWS also validates
# via the TLS chain, so this lets GitHub Actions assume an AWS role without
# any long-lived AWS access keys stored as repo secrets.
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      # GitHub's OIDC sub claim can append immutable numeric IDs to the owner
      # and repo names (e.g. "owner@123/repo@456:ref:...") instead of the
      # classic "owner/repo:ref:..." form — the trailing "*" on each segment
      # tolerates that optional "@<id>" suffix either way.
      values = ["repo:${split("/", var.github_repository)[0]}*/${split("/", var.github_repository)[1]}*:*"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

data "aws_iam_policy_document" "ecr_push" {
  statement {
    sid       = "ECRAuth"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "ECRPush"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = var.ecr_repository_arns
  }
}

resource "aws_iam_role_policy" "ecr_push" {
  name   = "${var.role_name}-ecr-push"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.ecr_push.json
}
