output "alb_dns_name" {
  description = "DNS name of the public ALB"
  value       = aws_lb.public_alb.dns_name
}

output "app_asg_name" {
  description = "Name of the App Autoscaling Group"
  value       = aws_autoscaling_group.app_asg.name
}

output "db_instance_endpoint" {
  description = "RDS Endpoint"
  value       = aws_db_instance.mysql_db.endpoint
}
