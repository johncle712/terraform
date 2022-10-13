module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "week19-vpc"
  cidr = var.vpc-cidr

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = []

  enable_nat_gateway = false
  enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "week19-vpc"
  }
}

resource "aws_ecs_cluster" "cluster" {
  name = "week19-ecs"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "cluster" {
  cluster_name = aws_ecs_cluster.cluster.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
  }
}

module "ecs-fargate" {
  source = "umotif-public/ecs-fargate/aws"
  version = "~> 6.1.0"

  name_prefix        = "week19-ecs"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets

  cluster_id         = aws_ecs_cluster.cluster.id

  task_container_image   = "centos"
  task_definition_cpu    = 256
  task_definition_memory = 512

  task_container_port             = 80
  task_container_assign_public_ip = true

load_balanced = false

  target_groups = [
    {
      target_group_name = "week19-tg"
      container_port    = 80
    }
  ]

  health_check = {
    port = "traffic-port"
    path = "/"
  }
}