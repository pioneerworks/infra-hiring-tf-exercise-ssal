locals {

  aws_region         = "us-east-1"
  cluster_name       = "tf-takehome"
  desired_capacity   = 2
  instance_type      = "t3.small"
  max_size           = 4
  min_size           = 2
  private_subnet_ids = ["subnet-12345678", "subnet-87654321"]
  public_subnet_ids  = ["subnet-23456789", "subnet-98765432"]
  ssh_key_name       = null
  vpc_id             = "vpc-12345678"

  userdata = <<-EOF
  #!/bin/bash
  set -eux
  cat > /etc/ecs/ecs.config <<EOC
  ECS_CLUSTER=${local.cluster_name}-cluster
  ECS_ENABLE_TASK_IAM_ROLE=true
  ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true
  ECS_AWSVPC_BLOCK_IMDS=true
  EOC
EOF
}

# service1
locals {
  service1_name                 = "service1"
  service1_admin_container_port = 8081
  service1_admin_image          = "public.ecr.aws/docker/library/httpd:latest"
  service1_api_container_port   = 8080
  service1_api_image            = "public.ecr.aws/docker/library/nginx:latest"
  service1_db_instance_class    = "db.t4g.micro"
  service1_db_name              = "appdb"
  service1_db_password          = "changeme123!"
  service1_db_username          = "appuser"
}
