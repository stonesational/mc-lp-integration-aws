
variable "aws_region" {
  description = "AWS Region. Picked us-west-2 at random"
  type        = string
  default     = "us-west-1"
}

variable "aws_account_id" {
  description = "Dan's AWS Account ID"
  type        = string
  default     = "274064898726"
}

variable "default_tags" {
  default     = {Project = "SFMC LP Integration"}
  description = "Default tags"
  type        = map(string)
}

variable "application_name" {
  default = "mc-lp-connector"
  description = "Common name of the application to be used consitantly for naming resources"
  type = string
}
