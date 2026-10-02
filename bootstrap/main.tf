data "aws_caller_identity" "current" {}

locals {
  acct = data.aws_caller_identity.current.account_id
}

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

resource "aws_iam_role_policy" "infra" {
  name = "deploy-infra"
  role = aws_iam_role.gha_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = "arn:aws:s3:::resume-bachelder-tfstate"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "arn:aws:s3:::resume-bachelder-tfstate/cloud-resume/terraform.tfstate"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:Get*",
          "s3:List*",
          "s3:PutBucketPolicy",
          "s3:PutBucketPublicAccessBlock",
          "s3:PutBucketTagging"
        ]
        Resource = "arn:aws:s3:::resume-bachelder"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudfront:Get*",
          "cloudfront:List*",
          "cloudfront:UpdateDistribution",
          "cloudfront:UpdateOriginAccessControl",
          "cloudfront:TagResource"
        ]
        Resource = [
          "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/EFO7NKGHS2UOM",
          "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:origin-access-control/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "backend" {
  name = "deploy-backend"
  role = aws_iam_role.gha_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudformation:CreateChangeSet",
          "cloudformation:DescribeChangeSet",
          "cloudformation:ExecuteChangeSet",
          "cloudformation:DeleteChangeSet",
          "cloudformation:DescribeStacks",
          "cloudformation:DescribeStackEvents",
          "cloudformation:GetTemplate",
          "cloudformation:GetTemplateSummary"
        ]
        Resource = [
          "arn:aws:cloudformation:us-east-1:${local.acct}:stack/cloud-resume-backend/*",
          "arn:aws:cloudformation:us-east-1:${local.acct}:stack/aws-sam-cli-managed-default/*",
          "arn:aws:cloudformation:us-east-1:aws:transform/Serverless-2016-10-31"
        ]
      },
      {
        Effect = "Allow"
        Action = ["s3:ListBucket", "s3:GetBucketLocation", "s3:GetObject", "s3:PutObject"]
        Resource = [
          "arn:aws:s3:::aws-sam-cli-managed-default-samclisourcebucket-*",
          "arn:aws:s3:::aws-sam-cli-managed-default-samclisourcebucket-*/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "lambda:*"
        Resource = "arn:aws:lambda:us-east-1:${local.acct}:function:visitor-counter"
      },
      {
        Effect   = "Allow"
        Action   = "dynamodb:*"
        Resource = "arn:aws:dynamodb:us-east-1:${local.acct}:table/visitor-count"
      },
      {
        Effect = "Allow"
        Action = ["apigateway:GET", "apigateway:POST", "apigateway:PATCH", "apigateway:PUT", "apigateway:DELETE", "apigateway:TagResource"]
        Resource = [
          "arn:aws:apigateway:us-east-1::/apis",
          "arn:aws:apigateway:us-east-1::/apis/*",
          "arn:aws:apigateway:us-east-1::/tags/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:TagRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:GetRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:PassRole"
        ]
        Resource = "arn:aws:iam::${local.acct}:role/cloud-resume-backend-*"
      }
    ]
  })
}