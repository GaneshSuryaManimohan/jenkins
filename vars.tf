variable "zone_name" {
    type = string
    default = "surya-devops.online"
}

variable "project_name" {
  type = string
  default = "expense"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "ami_id" {
    type = string
    default = "ami-0220d79f3f480ecf5"
}