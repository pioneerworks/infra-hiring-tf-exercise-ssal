# CloudWatch Log Groups

resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${local.service1_name}-api"
  retention_in_days = 7
}
resource "aws_cloudwatch_log_group" "admin" {
  name              = "/ecs/${local.service1_name}-admin"
  retention_in_days = 7
}
