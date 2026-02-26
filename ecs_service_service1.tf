# Roles for tasks

data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution" {
  name               = "${local.service1_name}-task-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

resource "aws_iam_role_policy_attachment" "task_exec_policy" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task_role" {
  name               = "${local.service1_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

# API Task Definition

resource "aws_ecs_task_definition" "api" {
  family                   = "${local.service1_name}-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name      = "api"
      image     = local.service1_api_image
      essential = true
      portMappings = [
        {
          containerPort = local.service1_api_container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.api.name
          awslogs-region        = local.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
      environment = [
        {
          name  = "DATABASE_HOST"
          value = aws_db_instance.pg.address
        },
        {
          name  = "DATABASE_NAME"
          value = local.service1_db_name
        },
        {
          name  = "DATABASE_USER"
          value = local.service1_db_username
        },
        {
          name  = "DATABASE_PASSWORD"
          value = local.service1_db_password
        }
      ]
    }
  ])
}

# ADMIN Task Definition

resource "aws_ecs_task_definition" "admin" {
  family                   = "${local.service1_name}-admin"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name      = "admin"
      image     = local.service1_admin_image
      essential = true
      portMappings = [
        {
          containerPort = local.service1_admin_container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.admin.name
          awslogs-region        = local.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# Security Group

resource "aws_security_group" "ecs_tasks_sg" {
  name        = "${local.service1_name}-tasks-sg"
  description = "ECS tasks"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = local.service1_api_container_port
    to_port         = local.service1_api_container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Services

resource "aws_ecs_service" "api" {
  name            = "${local.service1_name}-api"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets          = local.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api_tg.arn
    container_name   = "api"
    container_port   = local.service1_api_container_port
  }

  depends_on = [aws_lb_listener.http]
}

resource "aws_ecs_service" "admin" {
  name            = "${local.service1_name}-admin"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.admin.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets          = local.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }
}
