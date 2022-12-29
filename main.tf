terraform {
  backend "s3" {
    bucket                  = "tf-states-s3backend"
    key                     = "hello-rocket/main.tfstate"
    region                  = "us-east-1"
    encrypt                 = true
    profile                 = "default"
    dynamodb_table          = "tf-lock-table"
    shared_credentials_file = "$HOME/.aws/credentials"
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_ecr_repository" "rocket_ecr_repo" {
  name = "rocket-ecr-repo"
}

resource "aws_ecs_cluster" "rocket_cluster" {
  name = "rocket-cluster"
}

resource "aws_ecs_task_definition" "rocket_task" {
  family                   = "rocket-task"
  container_definitions    = <<DEFINITION
  [
    {
      "name": "rocket-task",
      "image": "${aws_ecr_repository.rocket_ecr_repo.repository_url}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 8000
        }
      ],
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = 512
  cpu                      = 256
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_alb" "rocket_app" {
  name               = "rocket-app-lb"
  internal           = false
  load_balancer_type = "application"

  subnets = [
    aws_subnet.public_d.id,
    aws_subnet.public_e.id,
  ]

  security_groups = [
    aws_security_group.http.id,
    aws_security_group.https.id,
    aws_security_group.egress_all.id,
  ]

  depends_on = [aws_internet_gateway.igw]
}


resource "aws_security_group" "load_balancer_security_group" {
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_lb_target_group" "rocket_app" {
  name        = "rocket-app"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.app_vpc.id

  health_check {
    enabled = true
    path    = "/health"
  }

  depends_on = [aws_alb.rocket_app]
}

resource "aws_alb_listener" "rocket_app_http" {
  load_balancer_arn = aws_alb.rocket_app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rocket_app.arn
  }
}

output "alb_url" {
  value = "http://${aws_alb.rocket_app.dns_name}"
}
resource "aws_ecs_service" "hello_rocket" {
  name            = "hello-rocket"
  cluster         = aws_ecs_cluster.rocket_cluster.id
  task_definition = aws_ecs_task_definition.rocket_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.rocket_app.arn
    container_name   = aws_ecs_task_definition.rocket_task.family
    container_port   = 8000
  }

  network_configuration {
    assign_public_ip = false

    security_groups = [
      aws_security_group.egress_all.id,
      aws_security_group.ingress_api.id,
    ]

    subnets = [
    aws_subnet.private_d.id,
    aws_subnet.private_e.id,
    ]
  }
}


resource "aws_security_group" "service_security_group" {
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
