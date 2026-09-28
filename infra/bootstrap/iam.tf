locals {
  environments = toset([
    "dev",
    "stage",
    "uat",
    "prod"
  ])

  tfstate_arn = "arn:${local.partition}:s3:::${var.state_bucket}"
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
  for_each = local.environments
  statement {
    sid       = "TerraformStateBucketLocation"
    actions   = ["s3:GetBucketLocation"]
    resources = [local.tfstate_arn]
  }
  statement {
    sid       = "EnvironmentStateListing"
    actions   = ["s3:ListBucket"]
    resources = [local.tfstate_arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${each.key}/*", "env:/"]
    }
  }
  statement {
    sid       = "EnvironmentStateLockDeletion"
    actions   = ["s3:DeleteObject"]
    resources = ["${local.tfstate_arn}/${each.key}/*.tflock"]
  }

  statement {
    sid = "TerraformStateObjects"

    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = [
      "${local.tfstate_arn}/${each.key}/platform.tfstate",
      "${local.tfstate_arn}/${each.key}/platform.tfstate.tflock",
      "${local.tfstate_arn}/${each.key}/network.tfstate",
      "${local.tfstate_arn}/${each.key}/network.tfstate.tflock"
    ]
  }

  statement {
    sid = "EC2Read"

    actions = [
      "ec2:Describe*",
      "ec2:GetLaunchTemplateData"
    ]

    resources = ["*"]
  }

  statement {
    sid = "EC2Manage"

    actions = [
      "ec2:AllocateAddress",
      "ec2:AssociateAddress",
      "ec2:AssociateRouteTable",
      "ec2:AttachInternetGateway",
      "ec2:AttachVolume",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateImage",
      "ec2:CreateInternetGateway",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateLaunchTemplateVersion",
      "ec2:CreateNatGateway",
      "ec2:CreateRoute",
      "ec2:CreateRouteTable",
      "ec2:CreateSecurityGroup",
      "ec2:CreateSnapshot",
      "ec2:CreateSubnet",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:CreateVpc",
      "ec2:DeleteInternetGateway",
      "ec2:DeleteLaunchTemplate",
      "ec2:DeleteLaunchTemplateVersions",
      "ec2:DeleteNatGateway",
      "ec2:DeleteRoute",
      "ec2:DeleteRouteTable",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteSnapshot",
      "ec2:DeleteSubnet",
      "ec2:DeleteTags",
      "ec2:DeleteVolume",
      "ec2:DeleteVpc",
      "ec2:DeregisterImage",
      "ec2:DetachInternetGateway",
      "ec2:DetachVolume",
      "ec2:DisassociateAddress",
      "ec2:DisassociateRouteTable",
      "ec2:ModifyLaunchTemplate",
      "ec2:ModifySubnetAttribute",
      "ec2:ModifyVpcAttribute",
      "ec2:ReleaseAddress",
      "ec2:ReplaceRoute",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RunInstances",
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:TerminateInstances"
    ]

    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid       = "LoadBalancerRead"
    actions   = ["elasticloadbalancing:Describe*"]
    resources = ["*"]
  }
  statement {
    sid     = "EnvironmentLoadBalancers"
    actions = ["elasticloadbalancing:*"]
    resources = [
      "arn:${local.partition}:elasticloadbalancing:${var.aws_region}:${local.account_id}:loadbalancer/app/${var.name_prefix}-${each.key}-*/*",
      "arn:${local.partition}:elasticloadbalancing:${var.aws_region}:${local.account_id}:targetgroup/${var.name_prefix}-${each.key}-*/*",
      "arn:${local.partition}:elasticloadbalancing:${var.aws_region}:${local.account_id}:listener/app/${var.name_prefix}-${each.key}-*/*/*",
      "arn:${local.partition}:elasticloadbalancing:${var.aws_region}:${local.account_id}:listener-rule/app/${var.name_prefix}-${each.key}-*/*/*/*"
    ]
  }

  statement {
    sid       = "AutoScalingRead"
    actions   = ["autoscaling:Describe*"]
    resources = ["*"]
  }
  statement {
    sid       = "EnvironmentAutoScaling"
    actions   = ["autoscaling:*"]
    resources = ["arn:${local.partition}:autoscaling:${var.aws_region}:${local.account_id}:autoScalingGroup:*:autoScalingGroupName/${var.name_prefix}-${each.key}-*"]
  }
}

data "aws_iam_policy_document" "deploy_services" {
  for_each = local.environments
  statement {
    sid       = "RDSRead"
    actions   = ["rds:Describe*", "rds:ListTagsForResource"]
    resources = ["*"]
  }
  statement {
    sid = "EnvironmentRDS"
    actions = [
      "rds:CreateDBInstance", "rds:ModifyDBInstance", "rds:DeleteDBInstance",
      "rds:CreateDBSubnetGroup", "rds:ModifyDBSubnetGroup", "rds:DeleteDBSubnetGroup",
      "rds:AddTagsToResource", "rds:RemoveTagsFromResource"
    ]
    resources = [
      "arn:${local.partition}:rds:${var.aws_region}:${local.account_id}:db:${var.name_prefix}-${each.key}-*",
      "arn:${local.partition}:rds:${var.aws_region}:${local.account_id}:subgrp:${var.name_prefix}-${each.key}-*",
      "arn:${local.partition}:rds:${var.aws_region}:${local.account_id}:snapshot:${var.name_prefix}-${each.key}-*"
    ]
  }

  statement {
    sid = "KMSForRDSAndSecrets"

    actions = [
      "kms:CreateGrant",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"

      values = [
        "rds.${var.aws_region}.amazonaws.com",
        "secretsmanager.${var.aws_region}.amazonaws.com"
      ]
    }
  }

  statement {
    sid       = "MonitoringRead"
    actions   = ["cloudwatch:DescribeAlarms", "cloudwatch:ListTagsForResource", "logs:DescribeLogGroups"]
    resources = ["*"]
  }
  statement {
    sid     = "EnvironmentMonitoring"
    actions = ["cloudwatch:PutDashboard", "cloudwatch:GetDashboard", "cloudwatch:DeleteDashboards", "cloudwatch:PutMetricAlarm", "cloudwatch:DeleteAlarms", "cloudwatch:TagResource", "cloudwatch:UntagResource", "logs:CreateLogGroup", "logs:DeleteLogGroup", "logs:PutRetentionPolicy", "logs:DeleteRetentionPolicy", "logs:ListTagsForResource", "logs:TagResource", "logs:UntagResource"]
    resources = [
      "arn:${local.partition}:cloudwatch::${local.account_id}:dashboard/${var.name_prefix}-${each.key}-*",
      "arn:${local.partition}:cloudwatch:${var.aws_region}:${local.account_id}:alarm:${var.name_prefix}-${each.key}-*",
      "arn:${local.partition}:logs:${var.aws_region}:${local.account_id}:log-group:/${var.name_prefix}/${each.key}/*"
    ]
  }

  statement {
    sid       = "PublicBaseImageParameter"
    actions   = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = ["arn:${local.partition}:ssm:${var.aws_region}::parameter/aws/service/ami-amazon-linux-latest/*"]
  }
  statement {
    sid       = "EnvironmentReadinessDocument"
    actions   = ["ssm:CreateDocument", "ssm:UpdateDocument", "ssm:UpdateDocumentDefaultVersion", "ssm:DeleteDocument", "ssm:DescribeDocument", "ssm:GetDocument", "ssm:AddTagsToResource", "ssm:RemoveTagsFromResource", "ssm:ListTagsForResource"]
    resources = ["arn:${local.partition}:ssm:${var.aws_region}:${local.account_id}:document/${var.name_prefix}-${each.key}-*"]
  }
  # Association IDs are service generated; instance/document checks need live validation.
  statement {
    sid       = "ReadinessAssociations"
    actions   = ["ssm:CreateAssociation", "ssm:UpdateAssociation", "ssm:DeleteAssociation", "ssm:DescribeAssociation", "ssm:ListAssociations", "ssm:DescribeAssociationExecutions", "ssm:DescribeAssociationExecutionTargets"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  # RDS creates service-named secrets. Deployment reads metadata, never credentials.
  statement {
    sid       = "RDSSecretMetadata"
    actions   = ["secretsmanager:CreateSecret", "secretsmanager:DescribeSecret", "secretsmanager:TagResource", "secretsmanager:ListSecretVersionIds", "secretsmanager:GetResourcePolicy"]
    resources = ["arn:${local.partition}:secretsmanager:${var.aws_region}:${local.account_id}:secret:rds!*"]
  }

  statement {
    sid = "CertificateManager"

    actions = [
      "acm:AddTagsToCertificate",
      "acm:DeleteCertificate",
      "acm:DescribeCertificate",
      "acm:ListCertificates",
      "acm:ListTagsForCertificate",
      "acm:RemoveTagsFromCertificate",
      "acm:RequestCertificate"
    ]

    resources = ["*"]
  }

  statement {
    sid = "Route53"

    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:GetChange",
      "route53:GetHostedZone",
      "route53:ListHostedZones",
      "route53:ListHostedZonesByName",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource"
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "deploy_iam" {
  for_each = local.environments
  statement {
    sid = "ProjectRoles"

    actions = [
      "iam:AddRoleToInstanceProfile",
      "iam:CreateInstanceProfile",
      "iam:CreateRole",
      "iam:DeleteInstanceProfile",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy",
      "iam:GetInstanceProfile",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:ListInstanceProfileTags",
      "iam:ListRolePolicies",
      "iam:PutRolePolicy",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:TagInstanceProfile",
      "iam:TagRole",
      "iam:UntagInstanceProfile",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:UpdateRoleDescription"
    ]

    resources = [
      "arn:${local.partition}:iam::${local.account_id}:role/${var.iam_name_prefix}-app-${each.key}",
      "arn:${local.partition}:iam::${local.account_id}:instance-profile/${var.iam_name_prefix}-app-${each.key}"
    ]
  }

  statement {
    sid       = "AttachOnlyRuntimeManagedPolicies"
    actions   = ["iam:AttachRolePolicy"]
    resources = ["arn:${local.partition}:iam::${local.account_id}:role/${var.iam_name_prefix}-app-${each.key}"]
    condition {
      test     = "ArnEquals"
      variable = "iam:PolicyARN"
      values   = ["arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore", "arn:${local.partition}:iam::aws:policy/CloudWatchAgentServerPolicy"]
    }
  }
  statement {
    sid       = "PassOnlyEnvironmentApplicationRole"
    actions   = ["iam:PassRole"]
    resources = ["arn:${local.partition}:iam::${local.account_id}:role/${var.iam_name_prefix}-app-${each.key}"]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"]
    }
  }

  statement {
    sid = "ReadAWSManagedPolicies"

    actions = [
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions"
    ]

    resources = ["arn:${local.partition}:iam::aws:policy/*"]
  }

  statement {
    sid       = "CreateRequiredServiceLinkedRoles"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "iam:AWSServiceName"

      values = [
        "autoscaling.amazonaws.com",
        "elasticloadbalancing.amazonaws.com",
        "rds.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_policy" "deploy_core" {
  for_each = local.environments

  name        = "${var.iam_name_prefix}-deploy-${each.key}-core"
  description = "CloudOpsTracker ${each.key}: Terraform state, VPC/EC2, ALB and Auto Scaling."
  policy      = data.aws_iam_policy_document.deploy_core[each.key].json
}

resource "aws_iam_policy" "deploy_services" {
  for_each = local.environments

  name        = "${var.iam_name_prefix}-deploy-${each.key}-services"
  description = "CloudOpsTracker ${each.key}: RDS, KMS, monitoring, SSM, secrets and HTTPS/DNS."
  policy      = data.aws_iam_policy_document.deploy_services[each.key].json
}

resource "aws_iam_policy" "deploy_iam" {
  for_each = local.environments

  name        = "${var.iam_name_prefix}-deploy-${each.key}-iam"
  description = "CloudOpsTracker ${each.key}: project IAM roles, instance profiles and service-linked roles."
  policy      = data.aws_iam_policy_document.deploy_iam[each.key].json
}

resource "aws_iam_role_policy_attachment" "deploy_core" {
  for_each = local.environments

  role       = aws_iam_role.deploy[each.key].name
  policy_arn = aws_iam_policy.deploy_core[each.key].arn
}

resource "aws_iam_role_policy_attachment" "deploy_services" {
  for_each = local.environments

  role       = aws_iam_role.deploy[each.key].name
  policy_arn = aws_iam_policy.deploy_services[each.key].arn
}

resource "aws_iam_role_policy_attachment" "deploy_iam" {
  for_each = local.environments

  role       = aws_iam_role.deploy[each.key].name
  policy_arn = aws_iam_policy.deploy_iam[each.key].arn
}
