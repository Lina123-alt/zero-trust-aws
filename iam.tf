# ============================================
# IAM - Groupes, roles et politiques
# Application du principe de moindre privilege
# ============================================

# ---- Politique personnalisee pour Terraform ----
# Remplace AdministratorAccess par des permissions precises

resource "aws_iam_policy" "terraform_deploy_policy" {
  name        = "${var.project_name}-terraform-deploy-policy"
  description = "Permissions minimales necessaires pour deployer l'infrastructure via Terraform"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2FullAccess"
        Effect = "Allow"
        Action = "ec2:*"
        Resource = "*"
      },
      {
        Sid    = "RDSFullAccess"
        Effect = "Allow"
        Action = "rds:*"
        Resource = "*"
      },
      {
        Sid    = "S3FullAccess"
        Effect = "Allow"
        Action = "s3:*"
        Resource = "*"
      },
      {
        Sid    = "AutoScalingFullAccess"
        Effect = "Allow"
        Action = "autoscaling:*"
        Resource = "*"
      },
      {
        Sid    = "ConfigFullAccess"
        Effect = "Allow"
        Action = "config:*"
        Resource = "*"
      },
      {
        Sid    = "CloudTrailFullAccess"
        Effect = "Allow"
        Action = "cloudtrail:*"
        Resource = "*"
      },
      {
        Sid    = "SNSFullAccess"
        Effect = "Allow"
        Action = "sns:*"
        Resource = "*"
      },
      {
        Sid    = "IAMScoped"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:ListAttachedUserPolicies",
          "iam:ListAttachedGroupPolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListRoles",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:ListPolicies",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:PassRole",
          "iam:CreateGroup",
          "iam:DeleteGroup",
          "iam:GetGroup",
          "iam:AttachGroupPolicy",
          "iam:DetachGroupPolicy",
          "iam:AddUserToGroup",
          "iam:RemoveUserFromGroup",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:ListPolicyVersions",
          "iam:GetPolicyVersion",
          "iam:TagRole",
          "iam:TagPolicy",
          "iam:ListInstanceProfilesForRole",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:GetInstanceProfile"
        ]
        Resource = "*"
      },
      {
        Sid    = "STSAccess"
        Effect = "Allow"
        Action = "sts:GetCallerIdentity"
        Resource = "*"
      }
    ]
  })
}

# ---- Groupe IAM pour les administrateurs d'infrastructure ----

resource "aws_iam_group" "infra_admins" {
  name = "${var.project_name}-infra-admins"
}

resource "aws_iam_group_policy_attachment" "infra_admins_policy" {
  group      = aws_iam_group.infra_admins.name
  policy_arn = aws_iam_policy.terraform_deploy_policy.arn
}

# ---- Role : Lecture seule (audit / visualisation) ----

resource "aws_iam_role" "readonly_auditor" {
  name = "${var.project_name}-readonly-auditor"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
      Action = "sts:AssumeRole"
      Condition = {
        Bool = {
          "aws:MultiFactorAuthPresent" = "true"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "readonly_auditor_policy" {
  role       = aws_iam_role.readonly_auditor.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ---- Role : Operateur reseau (VPC / Security Groups uniquement) ----

resource "aws_iam_role" "network_operator" {
  name = "${var.project_name}-network-operator"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
      Action = "sts:AssumeRole"
      Condition = {
        Bool = {
          "aws:MultiFactorAuthPresent" = "true"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "network_operator_policy" {
  name        = "${var.project_name}-network-operator-policy"
  description = "Permissions limitees a la gestion reseau (VPC, subnets, security groups)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "NetworkManagement"
        Effect = "Allow"
        Action = [
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeRouteTables",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "network_operator_attach" {
  role       = aws_iam_role.network_operator.name
  policy_arn = aws_iam_policy.network_operator_policy.arn
}

# ---- MFA : politique forcant l'authentification multifacteur ----

resource "aws_iam_policy" "require_mfa" {
  name        = "${var.project_name}-require-mfa"
  description = "Refuse toute action si le MFA n'est pas active"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyAllExceptListedIfNoMFA"
        Effect = "Deny"
        NotAction = [
          "iam:CreateVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:GetUser",
          "iam:ListMFADevices",
          "iam:ListVirtualMFADevices",
          "iam:ResyncMFADevice",
          "sts:GetSessionToken"
        ]
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "infra_admins_mfa" {
  group      = aws_iam_group.infra_admins.name
  policy_arn = aws_iam_policy.require_mfa.arn
}
