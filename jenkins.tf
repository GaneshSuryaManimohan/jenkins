terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.28.0"
    }
  }
}
provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "jenkins" {
    ami           = "ami-0220d79f3f480ecf5"
    instance_type = "t3.small"
    vpc_security_group_ids = ["sg-0bbdd2b154434fbfd"] 
    user_data = file("server.sh")
    tags = {
        Name = "jenkins-server"
    }
}

resource "aws_instance" "jenkins-agent" {
    ami           = "ami-0220d79f3f480ecf5"
    instance_type = "t3.medium"
    vpc_security_group_ids = ["sg-0bbdd2b154434fbfd"]
    user_data = file("agent.sh")
    tags = {
        Name = "jenkins-agent"
    }
}