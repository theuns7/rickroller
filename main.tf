# This is the main terraform file for doing stuff
# Author: Theuns Steyn 2022

# Provders (typically in provider.tf)
terraform {
  required_providers {
    aws = {
      source    = "hashicorp/aws"
      version   = "~> 4.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.20.0"
    }
  }
}

provider "aws" {
  region        = "us-east-1"
}

provider "docker" {}

# Variables (typically in variables.tf)
variable "vpc_id" {
  description = "VPC ID to use for AWS resources"
  default = "vpc-00c4c78c22e1922a9"
}

variable "subnet1_id" {
  description = "The first subnet to use"
  default = "subnet-0b21f234b0f4fc6d4"
}

variable "subnet2_id" {
  description = "The second subnet to use"
  default = "subnet-0bf1f7a7538566a79"
}


# Resources start

resource "aws_ecs_cluster" "cluster" {
  name = "ricroller-cluster"
}

resource "aws_ecs_cluster_capacity_providers" "cluster" {
  cluster_name          = aws_ecs_cluster.cluster.name
  capacity_providers    = ["FARGATE"]

  default_capacity_provider_strategy {
    base                = 1
    weight              = 100
    capacity_provider   = "FARGATE"
  }
}

resource "aws_ecs_service" "ecs_service" {
  name              = "rickroller-service"
  cluster           = aws_ecs_cluster.cluster.id
  task_definition   = aws_ecs_task_definition.ecs_task.arn
  launch_type       = "FARGATE"
  desired_count     = 1

  network_configuration {
    security_groups  = [aws_security_group.allow_http.id]
    assign_public_ip = true
    # Hard coded subnet ids. Use 2 of the subnets already created
    subnets = [var.subnet1_id, var.subnet2_id]
  }
}

resource "aws_ecs_task_definition" "ecs_task" {
  family                     = "service"
  network_mode               = "awsvpc"
  requires_compatibilities   = ["FARGATE"]
  cpu                        = 512
  memory                     = 1024
  container_definitions      = <<DEFINITION
  [
    {
      "name"                 : "rickroll",
      "image"                : "kale5/rickroll:latest",
      "cpu"                  : 512,
      "memory"               : 1024,
      "essential"            : true,
      "portMappings" : [
        {
          "containerPort"    : 80,
          "hostPort"         : 80
        }
      ]
    }
  ]
  DEFINITION
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP inbound and all outbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "ALL"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
