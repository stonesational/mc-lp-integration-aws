
# ----------------------------------------------------------------------------------------------------------------------
# ECS CLUSTER
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_ecs_cluster" "api-ecs-cluster" {
  name = "${var.application_name}-cluster"
}

# ----------------------------------------------------------------------------------------------------------------------
# TASK DEFINITION FOR AWS FARGATE
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_ecs_task_definition" "api-ecs-task" {
  family = "${var.application_name}-task"

  container_definitions = <<DEFINITION
  [
    {
      "name": "${var.application_name}-container",
      "image": "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.application_name}-ecr:latest",
      "environment": [ ],
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.app_log_group.id}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "${var.application_name}"
        }
      },
      "portMappings": [
        {
          "containerPort": 8080,
          "hostPort": 8080
        }
      ],
      "cpu": 256,
      "memory": 512,
      "networkMode": "awsvpc"
    }
  ]
  DEFINITION

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.apiEcsTaskRole.arn
}

data "aws_ecs_task_definition" "api_task_definition_data" {
  task_definition = aws_ecs_task_definition.api-ecs-task.family
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "${var.application_name}-execution-task-role"
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"]
  assume_role_policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "",
          "Action": "sts:AssumeRole",
          "Effect": "Allow",
          "Principal": {
            "Service": "ecs-tasks.amazonaws.com"
          }
        }
      ]
    }
    EOF
}

resource "aws_iam_role" "apiEcsTaskRole" {
  name               = "${var.application_name}-task-role"
  assume_role_policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "",
          "Action": "sts:AssumeRole",
          "Effect": "Allow",
          "Principal": {
            "Service": "ecs-tasks.amazonaws.com"
          }
        }
      ]
    }
    EOF
}

resource "aws_iam_role_policy" "ECSTaskRolePolicy" {
  name = "ECSTaskRolePolicy"
  role = aws_iam_role.apiEcsTaskRole.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["ecs:ExecuteCommand", "ssmmessages:CreateControlChannel", "ssmmessages:CreateDataChannel", "ssmmessages:OpenControlChannel", "ssmmessages:OpenDataChannel"],
            "Resource": "*"
        }
    ]
}
EOF
}


# ----------------------------------------------------------------------------------------------------------------------
# ECS SERVICE
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_ecs_service" "app-ecs-service" {
  name                   = "${var.application_name}-ecs-service"
  cluster                = aws_ecs_cluster.api-ecs-cluster.id
  task_definition        = "${aws_ecs_task_definition.api-ecs-task.family}:${max(aws_ecs_task_definition.api-ecs-task.revision, data.aws_ecs_task_definition.api_task_definition_data.revision)}"
  launch_type            = "FARGATE"
  scheduling_strategy    = "REPLICA"
  desired_count          = 1
  force_new_deployment   = true
  enable_execute_command = true

  network_configuration {
    subnets          = module.vpc.private_subnets
    assign_public_ip = false
    security_groups  = [aws_security_group.api_ecs_service.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api_target_group.arn
    container_name   = "${var.application_name}-container"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.inbound_elb_https_listener]
}


resource "aws_security_group" "api_ecs_service" {
  name        = "${var.application_name}-ecs-security-group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "From inbound_elb"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.inbound_elb.id]
  }

  ingress {
    description = "Peer to peer traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# AUTOSCALING TARGET
# Two policies. One to scale by CPU usage and the other to scale by Memory usage
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_appautoscaling_target" "api_ecs_target" {
  min_capacity       = 1
  max_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.api-ecs-cluster.name}/${aws_ecs_service.app-ecs-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  name               = "${var.application_name}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api_ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.api_ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api_ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = 80
  }
}

resource "aws_appautoscaling_policy" "api_ecs_policy_cpu" {
  name               = "${var.application_name}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api_ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.api_ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api_ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 80
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# ECR
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_ecr_repository" "ecr_edge_api_dev" {
  name         = "${var.application_name}-ecr"
  force_delete = true
}


# ----------------------------------------------------------------------------------------------------------------------
# CLOUDWATCH LOG GROUP
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "app_log_group" {
  name              = "/aws/fargate/${var.application_name}"
  retention_in_days = 7
}
