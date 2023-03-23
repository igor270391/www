output "all_users" {
  value = aws_iam_user.user-iam
}

# print all user arns
output "all_users_arn" {
  value = values(aws_iam_user.user-iam)[*].arn
}

# print arn of the attached policy to Neo
output "neo_cloudwatch_policy_arn" {
  value = one(concat(
    aws_iam_user_policy_attachment.neo_cloudwatch_full_access[*].policy_arn,
    aws_iam_user_policy_attachment.neo_cloudwatch_read_only[*].policy_arn
  ))
}