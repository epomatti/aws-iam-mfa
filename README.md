# aws-iam-mfa

Enforcing MFA for IAM logins

## Setup

Generate and export the `public.pgp` key:

```sh
gpg --quick-generate-key dev1
gpg --output public.pgp --export dev1
```

Apply the infrastructure:

```sh
terraform init
terraform apply -auto-approve
```

Get the user password:

```sh
terraform output password | base64 --decode | keybase pgp decrypt
```

## Testing

The user policy will deny the creation of EC2 resources based of the `aws:MultiFactorAuthPresent` condition.

```json
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
```

Delete the keys

```
gpg --list-keys
gpg --delete-secret-keys <KEY>
gpg --delete-keys <KEY>
```
