data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github" {
    url = "https://token.actions.githubusercontent.com"

    client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "gha_deploy" {
    name = "cloud-resume-gha-deploy"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Principal = {
                    Federated = aws_iam_openid_connect_provider.github.arn
                }
                Action = "sts:AssumeRoleWithWebIdentity"
                Condition = {
                    StringEquals = {
                        "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
                        "token.actions.githubusercontent.com:sub" = "repo:mbachel/cloud-resume:ref:refs/heads/main"
                    }
                }
            }
        ]
    })
}

resource "aws_iam_role_policy" "frontend" {
    name = "deploy-frontend"
    role = aws_iam_role.gha_deploy.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = "s3:ListBucket"
                Resource = "arn:aws:s3:::resume-bachelder"
            },
            {
                Effect = "Allow"
                Action = [
                    "s3:PutObject",
                    "s3:DeleteObject"
                ]
                Resource = "arn:aws:s3:::resume-bachelder/*"
            },
            {
                Effect = "Allow"
                Action = "cloudfront:CreateInvalidation"
                Resource = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/EFO7NKGHS2UOM"
            }
        ]
    })
}