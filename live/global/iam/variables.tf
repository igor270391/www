variable "user_names" {
    description = "Create IAM users with tese nnames"
    type = list(string)
    default = [ "neo", "trinity", "morpheus"]
}

variable "give_neo_cloudwatch_full_access" {
  description = "If true, neo gets full acess to CloudWatch"
  type = bool
}

variable "allowed_repos_brances" {
  description = "Github repos/brances allowed to assume the IAM role"
  type = list(object({
    org = string
    repo = string
    branch = string
  }))
}