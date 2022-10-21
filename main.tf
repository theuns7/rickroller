# This is the main terraform file for doing stuff


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
  description = "Allow HTTP inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
