env_prefix = "dev"
vpc_cidr = "192.168.0.0/16"
public_subnets = {
    ap-northeast-1a = {
        cidr_block = "192.168.0.0/24"
        tag = "abc-system-public-subnet-a"
    }

    ap-northeast-1c = {
        cidr_block = "192.168.1.0/24"
        tag = "abc-system-public-subnet-c"
    }
}
private_subnets = {
    ap-northeast-1a = {
        cidr_block = "192.168.3.0/24"
        tag = "abc-system-private-subnet-a"
    }

    ap-northeast-1c = {
        cidr_block = "192.168.4.0/24"
        tag = "abc-system-private-subnet-c"
    }
}

ecs_task_memory = 128
ecs_task_cpu = 10
ecs_desired_count = 2
ecs_health_check_grace_period_seconds = 60

# ecr_websrv_image_name = "nginx:1.19-alpine"
# ecr_appsrv_image_name = "php:8.0-fpm-alpine"
ecr_websrv_image_name = "public.ecr.aws/z9l7k5x5/test-ecs:docker_nginx-test-2"
ecr_appsrv_image_name = "public.ecr.aws/z9l7k5x5/test-ecs:docker_app-test-2"