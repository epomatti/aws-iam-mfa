terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.20.0"
    }
  }
}

resource "aws_iam_group" "developers" {
  name = "Developers"
  path = "/"
}

resource "aws_iam_user" "dev1" {
  name          = "Dev1"
  path          = "/"
  force_destroy = true
}

resource "aws_iam_user_group_membership" "dev1" {
  user = aws_iam_user.dev1.name

  groups = [
    aws_iam_group.developers.name
  ]
}

resource "aws_iam_user_login_profile" "dev1" {
  user                    = aws_iam_user.dev1.name
  password_reset_required = false
  pgp_key                 = filebase64("public.pgp")
}

resource "aws_iam_policy" "developers" {
  name = "DevelopersPolicy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:Describe*",
          "ec2:Get*",
          "s3:*",
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "BlockAnyAccessUnlessSignedInWithMFA",
        "Effect" : "Deny",
        "Action" : [
          "ec2:Create*",
          "ec2:Modify*",
          "ec2:Delete*",
          "ec2:Replace*",
          "ec2:Attach*",
          "ec2:Associate*",
        ],
        "Resource" : "*",
        "Condition" : {
          "BoolIfExists" : {
            "aws:MultiFactorAuthPresent" : false
          }
        }
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "developers" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.developers.arn
}
