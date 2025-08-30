terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  default = "us-east-1"
}

variable "project_name" {
  default = "infra-analyzer"
}

# IAM user for GitHub Actions
resource "aws_iam_user" "github_actions" {
  name = "${var.project_name}-github-actions"
}

resource "aws_iam_access_key" "github_actions" {
  user = aws_iam_user.github_actions.name
}

resource "aws_iam_user_policy" "github_actions_policy" {
  name = "${var.project_name}-github-policy"
  user = aws_iam_user.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "bedrock:InvokeModel"
        Resource = "arn:aws:bedrock:${var.aws_region}::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0"
      }
    ]
  })
}

# CloudWatch Log Group for monitoring
resource "aws_cloudwatch_log_group" "analyzer_logs" {
  name              = "/aws/github-actions/${var.project_name}"
  retention_in_days = 7
}

# Outputs for GitHub Secrets
output "aws_access_key_id" {
  value     = aws_iam_access_key.github_actions.id
  sensitive = true
}

output "aws_secret_access_key" {
  value     = aws_iam_access_key.github_actions.secret
  sensitive = true
}

output "setup_instructions" {
  value = <<EOF
Add these to your GitHub repository secrets:
- AWS_ACCESS_KEY_ID: ${aws_iam_access_key.github_actions.id}
- AWS_SECRET_ACCESS_KEY: ${aws_iam_access_key.github_actions.secret}
EOF
  sensitive = true
}
