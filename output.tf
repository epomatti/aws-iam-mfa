output "password" {
  value = aws_iam_user_login_profile.dev1.encrypted_password
}
