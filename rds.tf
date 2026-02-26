# DB subnet group (private subnets)
resource "aws_db_subnet_group" "pg" {
  name       = "${local.service1_name}-pg-subnets"
  subnet_ids = local.private_subnet_ids
}

resource "aws_security_group" "rds_sg" {
  name        = "${local.service1_name}-rds-sg"
  description = "Allow Postgres from ECS tasks"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "pg" {
  identifier              = "${local.service1_name}-pg"
  engine                  = "postgres"
  engine_version          = "15"
  instance_class          = local.service1_db_instance_class
  username                = local.service1_db_username
  password                = local.service1_db_password
  db_name                 = local.service1_db_name
  allocated_storage       = 20
  max_allocated_storage   = 100
  storage_type            = "gp3"
  publicly_accessible     = false
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.pg.name
  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false
  multi_az                = false
  apply_immediately       = true
}
