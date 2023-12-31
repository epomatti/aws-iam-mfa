# AWS IAM MFA

Enforcing MFA for IAM logins. Here is a short summary of configuration options:

- Deny temporary credentials, allow long-term credentials. (Not recommended)

```json
"Effect" : "Deny",
"Condition" : { "Bool" : { "aws:MultiFactorAuthPresent" : "false" } }
```
- Deny temporary credentials, deny long-term credentials.

```json

"Effect" : "Deny",
"Condition" : { "BoolIfExists" : { "aws:MultiFactorAuthPresent" : "false" } }
```

- Allow MFA-authenticated requests and AWS CLI or AWS API requests that are made using long-term credentials.

```json
"Effect" : "Allow",
"Condition" : { "BoolIfExists" : { "aws:MultiFactorAuthPresent" : "true" } }
```

- Allow programmatic and console requests only when authenticated using MFA.

```json
"Effect" : "Allow",
"Condition" : { "Bool" : { "aws:MultiFactorAuthPresent" : "true" } }
```

In a policy with `Deny` effect and when using the condition `BoolIfExists`, if the key `aws:MultiFactorAuthPresent` is not present in the context, it evaluates to `true`, meaning that the the `Deny` effect is applied. And if the key `aws:MultiFactorAuthPresent` is present but it's value is `false` (meaning that no MFA is present), then it also asserts to a `Deny`.

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

From the [documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_condition-keys.html#condition-keys-multifactorauthpresent):

> Use this key to check whether multi-factor authentication (MFA) was used to validate the temporary security credentials that made the request.

Notice that this condition validates the "**temporary** security credentials". Interpreting this sample policy:

```json
{
  "Sid" : "BlockAnyAccessUnlessSignedInWithMFA",
  "Effect" : "Deny",
  "Action" : [
    "ec2:*",
  ],
  "Resource" : "*",
  "Condition" : {
    "BoolIfExists" : {
      "aws:MultiFactorAuthPresent" : false
    }
  }
}
```

As detailed by the documentation:

```sh
#####   WARNING: NOT RECOMMENDED   #####
"Effect" : "Deny",
"Condition" : { "Bool" : { "aws:MultiFactorAuthPresent" : "false" } }
```
> This combination of the Deny effect, Bool element, and false value denies requests that can be authenticated using MFA, but were not. This applies only to temporary credentials that support using MFA. This statement does not deny access to requests that are made using long-term credentials, or to requests that are authenticated using MFA. Use this example with caution because its logic is complicated and it does not test whether MFA-authentication was actually used.

This is the recommended configuration:

> This combination of Deny, BoolIfExists, and false denies requests that are not authenticated using MFA. Specifically, it denies requests from temporary credentials that do not include MFA. It also denies requests that are made using long-term credentials, such as AWS CLI or AWS API operations made using access keys. The *IfExists operator checks for the presence of the aws:MultiFactorAuthPresent key and whether or not it could be present, as indicated by its existence. Use this when you want to deny any request that is not authenticated using MFA. This is more secure, but can break any code or scripts that use access keys to access the AWS CLI or AWS API.

```sh
"Effect" : "Deny",
"Condition" : { "BoolIfExists" : { "aws:MultiFactorAuthPresent" : "false" } }
```

To authenticate using MFA while using the CLI, follow the steps in the [documentation](https://repost.aws/knowledge-center/authenticate-mfa-cli).

Instruct users to run the `aws sts get-session-token` CLI command and pass the multi-factor authentication `--serial-number` and `--token-code` parameters. Use these resulting values to make API/CLI calls.

```sh
# Snippet only
aws sts get-session-token --serial-number arn-of-the-mfa-device --token-code code-from-token
```

Read the documentation for a complete reference.


## Clean-up

Destroy the infrastructure:

```sh
terraform destroy -auto-approve
```

Delete the keys:

```
gpg --list-keys
gpg --delete-secret-keys <KEY>
gpg --delete-keys <KEY>
```
