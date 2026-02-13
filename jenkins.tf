terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.28.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}

#############################################
# IAM Role for Jenkins EC2
#############################################

resource "aws_iam_role" "jenkins_role" {
  name = "jenkins-terraform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

#############################################
# Attach AdministratorAccess (Practice Only)
#############################################

resource "aws_iam_role_policy_attachment" "jenkins_admin_attach" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

#############################################
# Instance Profile (Required for EC2)
#############################################

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins-instance-profile"
  role = aws_iam_role.jenkins_role.name
}


resource "aws_instance" "jenkins" {
  ami                    = "ami-0220d79f3f480ecf5"
  instance_type          = "t3.small"
  vpc_security_group_ids = ["sg-0bbdd2b154434fbfd"]
  subnet_id              = "subnet-00d8b90d93d5ad88f"
  user_data              = file("server.sh")
  tags = {
    Name = "jenkins-server"
  }
}

resource "aws_instance" "jenkins-agent" {
  ami                    = "ami-0220d79f3f480ecf5"
  instance_type          = "t3.medium"
  vpc_security_group_ids = ["sg-0bbdd2b154434fbfd"]
  subnet_id              = "subnet-00d8b90d93d5ad88f"
  user_data              = file("agent.sh")
  iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name
  tags = {
    Name = "jenkins-agent"
  }
}

resource "aws_instance" "nexus" {
  ami         = "ami-0220d79f3f480ecf5"
  instance_type = "t2.medium"
  user_data = file("nexus-install.sh")
  subnet_id = "subnet-00d8b90d93d5ad88f"
  vpc_security_group_ids = ["sg-0bbdd2b154434fbfd"]
  tags = {
    Name = "Nexus-Server"
  }
}


resource "aws_route53_record" "jenkins-server" {
  zone_id = data.aws_route53_zone.existing.zone_id
  name    = "jenkins.${var.zone_name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.jenkins.public_ip]
}


resource "aws_route53_record" "jenkins-agent" {
  zone_id = data.aws_route53_zone.existing.zone_id
  name    = "agent.${var.zone_name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.jenkins-agent.private_ip]
}

resource "aws_route53_record" "nexus" {
  zone_id = data.aws_route53_zone.existing.zone_id
  name    = "nexus.${var.zone_name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.nexus.public_ip]
}