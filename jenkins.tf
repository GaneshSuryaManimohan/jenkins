terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.28.0"
    }
  }
  backend "s3" {
    bucket = "backend-remote-s3-bucket"
    key = "expense-jenkins"
    region = "us-east-1"
    dynamodb_table = "s3-bucket-locking"
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

# Security Group for Jenkins Server
resource "aws_security_group" "jenkins_server" {
  name   = "${var.project_name}-${var.environment}-jenkins-server"
  vpc_id = data.aws_ssm_parameter.vpc_id.value

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-jenkins-server"
  }
}

# Security Group for Jenkins Agent

resource "aws_security_group" "jenkins_agent" {
  name   = "${var.project_name}-${var.environment}-jenkins-agent"
  vpc_id = data.aws_ssm_parameter.vpc_id.value

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-jenkins-agent"
  }
}

# Security Group rule allowing jenkins agent to communicate with EKS Cluster SG 
resource "aws_security_group_rule" "jenkins_agent_to_eks" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = data.aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.jenkins_agent.id
}

#############################################
# Instance Profile (Required for EC2)
#############################################

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins-instance-profile"
  role = aws_iam_role.jenkins_role.name
}


resource "aws_instance" "jenkins" {
  ami                    = var.ami_id
  instance_type          = "t3.small"
  vpc_security_group_ids = [aws_security_group.jenkins_server.id]
  subnet_id              = split(",", data.aws_ssm_parameter.public_subnet_ids.value)[0]
  user_data              = file("server.sh")
  tags = {
    Name = "jenkins-server"
  }
}

resource "aws_instance" "jenkins-agent" {
  ami                    = var.ami_id
  instance_type          = "t3.medium"
  vpc_security_group_ids = [aws_security_group.jenkins_agent.id]
  subnet_id              = split(",", data.aws_ssm_parameter.private_subnet_ids.value)[1]
  user_data              = file("agent.sh")
  iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name
  tags = {
    Name = "jenkins-agent"
  }
}

resource "aws_instance" "nexus" {
  ami         = var.ami_id
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