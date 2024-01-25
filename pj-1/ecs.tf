// 変数
// ------------------------------------------------
variable ecs_task_memory {
  type = number
  description = "(optional) describe your variable"
}

variable ecs_task_cpu {
  type = number
  description = "(optional) describe your variable"
}

variable ecs_desired_count {
  type = number
  description = "(optional) describe your variable"
}

variable ecs_health_check_grace_period_seconds {
  type = number
  description = "(optional) describe your variable"
}
variable ecr_websrv_image_name {
  type = string
  description = "(optional) describe your variable"
}
variable ecr_appsrv_image_name {
  type = string
  description = "(optional) describe your variable"
}

// ------------------------------------------------

// リソース
// ------------------------------------------------
# ECSクラスタの作成
resource "aws_ecs_cluster" "cluster" {
    # count  = var.env_prefix == "prd" ? 1 : 0　　　　   #このように書けば本番環境のみ作成するリソースとなる
    name = local.ecs_cluster_name
    setting {
        name  = "containerInsights"
        value = "enabled"
    }
    tags = {
        Name = local.ecs_cluster_name
    }
}

# タスク定義の作成
resource "aws_ecs_task_definition" "task_def" {
    family                   = local.ecs_family_name
    network_mode             = "awsvpc"
    cpu    = 256
    memory = 512
    requires_compatibilities = ["FARGATE"]
    execution_role_arn       = aws_iam_role.ecs_execution.arn
    task_role_arn            = aws_iam_role.ecs_task.arn
    container_definitions = templatefile("task_def.json",
        {
            cpu = var.ecs_task_cpu
            memory = var.ecs_task_memory
            ecs_container_name = local.ecs_container_name
            app_img = var.ecr_appsrv_image_name
            web_img = var.ecr_websrv_image_name
            cwlogs_web = local.ecs_web_cwlogs_name
            cwlogs_app = local.ecs_app_cwlogs_name

        }
    )
    tags = {
        Name = local.ecs_task_name
    }
}

# タスク起動用IAMロールの定義
resource "aws_iam_role" "ecs_execution" {
    name = local.iam_ecs_execution_role_name
    assume_role_policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
            "Service": "ecs-tasks.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
        ]
    })
    tags = {
        Name = local.iam_ecs_execution_role_name
    }
}

# タスク起動用IAMロールへのポリシー割り当て
resource "aws_iam_role_policy_attachment" "ecs_execution" {
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
    role       = aws_iam_role.ecs_execution.name
}

# コンテナ用IAMロールの定義
resource "aws_iam_role" "ecs_task" {
    name = local.iam_ecs_task_role_name
    assume_role_policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
            "Service": "ecs-tasks.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
        ]
    })
    tags = {
        Name = local.iam_ecs_task_role_name
    }
}

# コンテナ用IAMポリシーの定義（例ではSSMパラメータストアのアクセス権限を付与）
resource "aws_iam_policy" "ecs_task" {
    name = local.iam_ecs_task_policy_name
    path = "/service-role/"
    policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
        {
            "Action": [
            "ssm:GetParametersByPath",
            "ssm:GetParameters",
            "ssm:GetParameter"
            ],
            "Effect": "Allow",
            "Resource": [
            "*"
            ]
        }
        ]
    })
    tags = {
        Name = local.iam_ecs_task_policy_name
    }
}

# コンテナ用IAMロールへのポリシー割り当て
resource "aws_iam_role_policy_attachment" "ecs_task" {
    policy_arn = aws_iam_policy.ecs_task.arn
    role       = aws_iam_role.ecs_task.name
}

#ここまではPlan OK














data "aws_ecs_task_definition" "task_def" {
  task_definition = aws_ecs_task_definition.task_def.family
  depends_on = [aws_ecs_task_definition.task_def]
}


# ECSサービスの作成
resource "aws_ecs_service" "service" {
    name                              = local.ecs_service_name
    cluster                           = aws_ecs_cluster.cluster.id
    task_definition                   = data.aws_ecs_task_definition.task_def.arn
    desired_count                     = var.ecs_desired_count
    health_check_grace_period_seconds = var.ecs_health_check_grace_period_seconds
    launch_type                       = "FARGATE"
    force_new_deployment              = local.ecs_force_new_deployment
    triggers = {
        redeployment = timestamp()
    }
    network_configuration {
        security_groups = [aws_security_group.ecs_service.id]
        subnets         = flatten([ values(aws_subnet.private)[*].id])
        assign_public_ip = false # private subnetに配置しているため
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.ecs_tg.arn
        container_name   = local.ecs_container_name
        container_port   = local.ecs_container_port
    }
  lifecycle {
    ignore_changes = [
      task_definition, # デプロイ毎にタスク定義は変更されるため
      desired_count,
    ]
  }
    tags = {
        Name = local.ecs_service_name
    }

    depends_on = [aws_alb.ecs_alb, aws_subnet.private]
}

# ECS Serviceのセキュリティグループの定義（通信制御の定義は割愛）
resource "aws_security_group" "ecs_service" {
    name   = local.ecs_security_group_name
    vpc_id = aws_vpc.vpc.id
    description = "test ecs"

    # セキュリティグループ内のリソースからインターネットへのアクセス許可設定
    # 今回の場合DockerHubへのPullに使用する。
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
        Name = local.ecs_security_group_name
    }

    lifecycle {
        create_before_destroy = true
    }
}

# ELB のセキュリティグループの定義（通信制御の定義は割愛）
resource "aws_security_group" "ecs_alb" {
    name   = local.ecs_alb_security_group_name
    vpc_id = aws_vpc.vpc.id
    description = "test alb"

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
    tags = {
        Name = local.ecs_alb_security_group_name
    }

    lifecycle {
        create_before_destroy = true
    }
}

# ALB向けのECSサービス用ターゲットグループの定義
resource "aws_lb_target_group" "ecs_tg" {
    name        = local.ecs_alb_target_group_name
    port        = local.ecs_container_port
    protocol    = "HTTP"
    target_type = "ip"
    vpc_id      = aws_vpc.vpc.id

  health_check {
    healthy_threshold   = "3"
    interval            = "300"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }

    tags = {
        Name = local.ecs_alb_target_group_name
    }
}

resource "aws_ecr_repository" "ecs_ecr" {
  name = local.ecs_ecr_name
  tags = {
    Name        = local.ecs_ecr_name
  }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id
    tags = {
        Name        = local.igw_name
    }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = local.route_table_public_name
  }
}

resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = local.route_table_private_a_name
  }
}

resource "aws_route_table" "private_c" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = local.route_table_private_c_name
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "private_a" {
  route_table_id         = aws_route_table.private_a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.ntgw_a.id
}

resource "aws_route" "private_c" {
  route_table_id         = aws_route_table.private_c.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.ntgw_c.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = element(flatten([ values(aws_subnet.public)[*].id]), count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = flatten([ values(aws_subnet.private)[*].id])[0]
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_c" {
  subnet_id      = flatten([ values(aws_subnet.private)[*].id])[1]
  route_table_id = aws_route_table.private_c.id
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = local.ecs_cwlogs_name

  tags = {
    Application = local.ecs_cwlogs_name
  }
}

resource "aws_alb" "ecs_alb" {
  name               = local.ecs_alb_name
  internal           = false
  load_balancer_type = "application"
  subnets            = flatten([ values(aws_subnet.public)[*].id])
  security_groups    = [aws_security_group.ecs_alb.id]

  tags = {
    Name        = local.ecs_alb_name
  }

  depends_on = [aws_subnet.public]
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_alb.ecs_alb.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.id
  }
}

# NATゲートウェイリソースを作成
resource "aws_nat_gateway" "ntgw_a" {
  allocation_id = aws_eip.nat[0].id  // 最初のEIP（Elastic IP）を使用
  subnet_id     = flatten([ values(aws_subnet.public)[*].id])[0]  // NATゲートウェイに関連付けるサブネットのID

  tags = {
    Name = "nat_gw_test"  // NATゲートウェイの名前
  }
}
resource "aws_nat_gateway" "ntgw_c" {
  allocation_id = aws_eip.nat[1].id  // 最初のEIP（Elastic IP）を使用
  subnet_id     = flatten([ values(aws_subnet.public)[*].id])[1]  // NATゲートウェイに関連付けるサブネットのID

  tags = {
    Name = "nat_gw_test"  // NATゲートウェイの名前
  }
}

# Elastic IPリソースを作成
resource "aws_eip" "nat" {
  count  = 2  // 作成するEIPの数
  domain = "vpc"  // VPC内でEIPを使用（vpc = trueの代わりに）
}





# autoscaling.tf | Auto Scaling Group
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_asg_policy_memory" {
  name               = local.ecs_asg_memory_policy_name
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = 80
  }
}

resource "aws_appautoscaling_policy" "ecs_asg_policy_cpu" {
  name               = local.ecs_asg_cpu_policy_name
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 80
  }
}

resource "aws_cloudwatch_log_group" "web_cwlog" {
  name = "${local.ecs_web_cwlogs_name}"
  retention_in_days = 30
  tags = {
    app = "serviceA"
  }
  depends_on = [ aws_ecs_task_definition.task_def ]
}

resource "aws_cloudwatch_log_group" "app_cwlog" {
  name = "${local.ecs_app_cwlogs_name}"
  retention_in_days = 30
  tags = {
    app = "serviceA"
  }
  depends_on = [ aws_ecs_task_definition.task_def ]
}