locals {
  environments = toset(["dev", "stage", "uat", "prod"])
  tfstate_arn  = "arn:${local.partition}:s3:::${var.state_bucket}"
}

data "aws_iam_policy_document" "github_environment_trust" {
  for_each = local.environments

  statement {
    sid     = "GitHubOIDC${title(each.key)}"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_oidc_repo_segment}:environment:${each.key}"]
    }
  }
}

resource "aws_iam_role" "deploy" {
  for_each = local.environments
  name                 = "${var.iam_name_prefix}-deploy-${each.key}"
  description          = "CloudOpsTracker GitHub Actions deployment role for ${each.key}."
  assume_role_policy   = data.aws_iam_policy_document.github_environment_trust[each.key].json
  max_session_duration = 3600

  tags = {
    Project     = var.name_prefix
    Environment = each.key
  }
}

data "aws_iam_policy_document" "deploy_core" {
  statement {
    sid       = "TerraformStateBucket"
    actions   = ["s3:GetBucketLocation", "s3:ListBucket"]
    resources = [local.tfstate_arn]
  }

  statement {
    sid       = "TerraformStateObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${local.tfstate_arn}/*"]
  }

  statement {
    sid       = "EC2Read"
    actions   = ["ec2:Describe*", "ec2:GetLaunchTemplateData"]
    resources = ["*"]
  }

  statement {
    sid = "EC2Manage"
    actions = [
      "ec2:AllocateAddress", "ec2:AssociateAddress", "ec2:AssociateRouteTable",
      "ec2:AttachInternetGateway", "ec2:AttachVolume", "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress", "ec2:CreateImage", "ec2:CreateInternetGateway",
      "ec2:CreateLaunchTemplate", "ec2:CreateLaunchTemplateVersion", "ec2:CreateNatGateway",
      "ec2:CreateRoute", "ec2:CreateRouteTable", "ec2:CreateSecurityGroup",
      "ec2:CreateSnapshot", "ec2:CreateSubnet", "ec2:CreateTags", "ec2:CreateVolume",
      "ec2:CreateVpc", "ec2:DeleteInternetGateway", "ec2:DeleteLaunchTemplate",
      "ec2:DeleteLaunchTemplateVersions", "ec2:DeleteNatGateway", "ec2:DeleteRoute",
      "ec2:DeleteRouteTable", "ec2:DeleteSecurityGroup", "ec2:DeleteSnapshot",
      "ec2:DeleteSubnet", "ec2:DeleteTags", "ec2:DeleteVolume", "ec2:DeleteVpc",
      "ec2:DeregisterImage", "ec2:DetachInternetGateway", "ec2:DetachVolume",
      "ec2:DisassociateAddress", "ec2:DisassociateRouteTable", "ec2:ModifyLaunchTemplate",
      "ec2:ModifySubnetAttribute", "ec2:ModifyVpcAttribute", "ec2:ReleaseAddress",
      "ec2:ReplaceRoute", "ec2:RevokeSecurityGroupEgress", "ec2:RevokeSecurityGroupIngress",
      "ec2:RunInstances", "ec2:StartInstances", "ec2:StopInstances", "ec2:TerminateInstances"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "LoadBalancer"
    actions   = ["elasticloadbalancing:*"]
    resources = ["*"]
  }

  statement {
    sid       = "AutoScaling"
    actions   = ["autoscaling:*"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "deploy_services" {
  statement { sid = "RDS" actions = ["rds:*"] resources = ["*"] }
  statement { sid = "CloudWatch" actions = ["cloudwatch:*", "logs:*"] resources = ["*"] }
  statement { sid = "SystemsManager" actions = ["ssm:*"] resources = ["*"] }
  statement {
    sid = "SecretsManager"
    actions = [
      "secretsmanager:CreateSecret", "secretsmanager:DeleteSecret", "secretsmanager:DescribeSecret",
      "secretsmanager:GetResourcePolicy", "secretsmanager:GetSecretValue",
      "secretsmanager:ListSecretVersionIds", "secretsmanager:PutResourcePolicy",
      "secretsmanager:PutSecretValue", "secretsmanager:RestoreSecret",
      "secretsmanager:TagResource", "secretsmanager:UntagResource", "secretsmanager:UpdateSecret"
    ]
    resources = ["*"]
  }
  statement {
    sid = "CertificateManager"
    actions = [
      "acm:AddTagsToCertificate", "acm:DeleteCertificate", "acm:DescribeCertificate",
      "acm:ListCertificates", "acm:ListTagsForCertificate", "acm:RemoveTagsFromCertificate",
      "acm:RequestCertificate"
    ]
    resources = ["*"]
  }
  statement {
    sid = "Route53"
    actions = [
      "route53:ChangeResourceRecordSets", "route53:GetChange", "route53:GetHostedZone",
      "route53:ListHostedZones", "route53:ListHostedZonesByName", "route53:ListResourceRecordSets"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "deploy_iam" {
  statement {
    sid = "ProjectRoles"
    actions = [
      "iam:AddRoleToInstanceProfile", "iam:AttachRolePolicy", "iam:CreateInstanceProfile",
      "iam:CreateRole", "iam:DeleteInstanceProfile", "iam:DeleteRole", "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy", "iam:GetInstanceProfile", "iam:GetRole", "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies", "iam:ListInstanceProfilesForRole", "iam:ListRolePolicies",
      "iam:PassRole", "iam:PutRolePolicy", "iam:RemoveRoleFromInstanceProfile", "iam:TagRole",
      "iam:UntagRole", "iam:UpdateAssumeRolePolicy", "iam:UpdateRoleDescription"
    ]
    resources = [
      "arn:${local.partition}:iam::${local.account_id}:role/${var.iam_name_prefix}-*",
      "arn:${local.partition}:iam::${local.account_id}:instance-profile/${var.iam_name_prefix}-*"
    ]
  }

  statement {
    sid       = "ReadAWSManagedPolicies"
    actions   = ["iam:GetPolicy", "iam:GetPolicyVersion", "iam:ListPolicyVersions"]
    resources = ["arn:${local.partition}:iam::aws:policy/*"]
  }

  statement {
    sid       = "CreateRequiredServiceLinkedRoles"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "iam:AWSServiceName"
      values   = ["autoscaling.amazonaws.com", "elasticloadbalancing.amazonaws.com", "rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "deploy_core" {
  for_each    = local.environments
  name        = "${var.iam_name_prefix}-deploy-${each.key}-core"
  description = "CloudOpsTracker ${each.key}: Terraform state, VPC/EC2, ALB and Auto Scaling."
  policy      = data.aws_iam_policy_document.deploy_core.json
}

resource "aws_iam_policy" "deploy_services" {
  for_each    = local.environments
  name        = "${var.iam_name_prefix}-deploy-${each.key}-services"
  description = "CloudOpsTracker ${each.key}: RDS, monitoring, SSM, secrets and HTTPS/DNS."
  policy      = data.aws_iam_policy_document.deploy_services.json
}

resource "aws_iam_policy" "deploy_iam" {
  for_each    = local.environments
  name        = "${var.iam_name_prefix}-deploy-${each.key}-iam"
  description = "CloudOpsTracker ${each.key}: project IAM roles and service-linked roles."
  policy      = data.aws_iam_policy_document.deploy_iam.json
}

resource "aws_iam_role_policy_attachment" "deploy_core" {
  for_each   = local.environments
  role       = aws_iam_role.deploy[each.key].name
  policy_arn = aws_iam_policy.deploy_core[each.key].arn
}

resource "aws_iam_role_policy_attachment" "deploy_services" {
  for_each   = local.environments
  role       = aws_iam_role.deploy[each.key].name
  policy_arn = aws_iam_policy.deploy_services[each.key].arn
}

resource "aws_iam_role_policy_attachment" "deploy_iam" {
  for_each   = local.environments
  role       = aws_iam_role.deploy[each.key].name
  policy_arn = aws_iam_policy.deploy_iam[each.key].arn
}
