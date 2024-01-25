variable env_prefix{
    type = string
    description = "(optional) describe your variable"
}



locals{
    pj_prefix = "abc-system"
    name_prefix = "${var.env_prefix}-${local.pj_prefix}"
    ecs_cluster_name = "${local.name_prefix}-ecs-cluster"
    ecs_task_name = "${local.name_prefix}-ecs-task"
    iam_ecs_execution_role_name = "${local.name_prefix}-ecs-execution_role"
    iam_ecs_task_role_name = "${local.name_prefix}-ecs-task_role"
    iam_ecs_task_policy_name = "${local.name_prefix}-ecs-task_policy"
    ecs_service_name = "${local.name_prefix}-ecs-service"
    ecs_force_new_deployment = true

    ecs_container_name = "${local.name_prefix}-ecs-app-container"
    ecs_container_port = 80
    ecs_security_group_name = "${local.name_prefix}-ecs-sg"
    ecs_alb_security_group_name = "${local.name_prefix}-ecs-alb-sg"
    ecs_family_name = "${var.env_prefix}-${local.pj_prefix}-ecs-task-def"

    ecs_alb_name = "${var.env_prefix}-${local.pj_prefix}-ecs-alb"
    ecs_alb_target_group_name = "${var.env_prefix}-${local.pj_prefix}-ecs-target-group"
    ecs_ecr_name = "${var.env_prefix}-${local.pj_prefix}-ecs-ecr"
    ecs_asg_memory_policy_name = "${var.env_prefix}-${local.pj_prefix}-ecs-asg-memory-policy"
    ecs_asg_cpu_policy_name = "${var.env_prefix}-${local.pj_prefix}-ecs-asg-cpu-policy"

    igw_name = "${var.env_prefix}-${local.pj_prefix}-igw"
    route_table_public_name = "${var.env_prefix}-${local.pj_prefix}-routing-table-public"
    route_table_private_a_name = "${var.env_prefix}-${local.pj_prefix}-routing-table-private-a"
    route_table_private_c_name = "${var.env_prefix}-${local.pj_prefix}-routing-table-private-c"
    ecs_cwlogs_name = "${var.env_prefix}-${local.pj_prefix}-ecs_logs"

    ecs_web_cwlogs_name = "/ecs/${var.env_prefix}-${local.pj_prefix}/web/"
    ecs_app_cwlogs_name = "/ecs/${var.env_prefix}-${local.pj_prefix}/app/"
}


