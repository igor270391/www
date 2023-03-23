terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
    region = "us-east-2"
}

# the same with for_each
/* resource "aws_iam_user" "user-iam" {
    count = length(var.user_names)
    name = var.user_names[count.index]
} */


resource "aws_iam_user" "user_iam" {
    for_each = toset(var.user_names)
    name = each.value
}

#IAM policy that allows read-only access to CloudWatch
resource "aws_iam_policy" "cloudwatch_read_only" {
  name = "cloudwatch-read-only"
  policy = aws_iam_policy_document.cloudwatch_read_only.json
}

data "aws_iam_policy_document" "cloudwatch_read_only" {
  statement {
    effect = "Allow"
    actions = [
        "cloudwatch:Describe*",
        "cloudwatch:Get*",
        "cloudwatch:List*"
    ]
    resources = ["*"]
  }
}

#IAM policy that allows full access (read and write) to CloudWatch
resource "aws_iam_policy" "cloudwatch_full_access" {
  name = "cloudwatch-read-only"
  policy = aws_iam_policy_document.cloudwatch_full_access.json
}

data "aws_iam_policy_document" "cloudwatch_full_access" {
  statement {
    effect = "Allow"
    actions = ["cloudwatch:*"]
    resources = ["*"]
  }
}

resource "aws_iam_user_policy_attachment" "neo_cloudwatch_full_access" {
  count = var.give_neo_cloudwatch_full_access ? 1 : 0

  user = aws.aws_iam_user.user_iam[0].name
  policy_arn = aws_iam_policy.cloudwatch_full_access.arn
}

resource "aws_iam_user_policy_attachment" "neo_cloudwatch_read_only" {
  count = var.give_neo_cloudwatch_full_access ? 0 : 1

  user = aws.aws_iam_user.user_iam[0].name
  policy_arn = aws_iam_policy.cloudwatch_full_access.arn
}


# Assume IAM role
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
############
# -----EC2 instnces running Jenkins with IAM roles
# create AIM role passing to "aws_iam_policy_document" "assume_role" 
resource "aws_iam_role" "instance" {
  name_prefix = var.name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Create an IAM policy that grants EC2 admin permissions
data "aws_iam_policy_document" "ec2_admin_permissions" {
  statement {
    effect = "Allow"
    actions = ["ec2:*"]
    resources = ["*"]
  }
}

# Attach the EC2 admin permissions to the IAM role
resource "aws_iam_role_policy" "ec2_admin_role" {
  role = aws_iam_role.instance.id
  policy = data.aws_iam_policy_document.ec2_admin_permissions.json
}

# final step is to allow EC2 to automatic. assueme that IAM role by creating instance profile
resource "aws_iam_instance_profile" "instance_profile" {
  role = aws_iam_role_policy.ec2_admin_role.name
}

###############
# Github actions with OIDC (Open ID content)
# 1) create IAM OIDC identity provider
# 2) configure it to trust the github Actions fetched via tls_certificate

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    data.tls_certificate.github.tls_certificates[0].sha1_finger_print
  ]
}

# fetch GitHub's thumbprint
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# creat IAM role as in previos but with asume role diferent
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect = "Allow"

    principals {
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
      type = "Federated"
    }

    condition {
      test = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"

      # the repos and branchesdefined in var.allowed_repos_brances will be able to assume this role
      values = [
        for a in var.allowed_repos_branches :
        "repo: ${a["org"]}/${a["repo"]}:ref:refs/heads/${a["branch"]}"
      ]
    }
  }
}