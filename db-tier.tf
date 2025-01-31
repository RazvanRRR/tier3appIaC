######################
# DB SECURITY GROUP  #
######################

resource "aws_security_group" "db_sg" {
  name        = "db-sg-${var.environment}"
  description = "DB tier security group"
  vpc_id      = aws_vpc.main.id

  # Inbound from App SG on port 3306
  ingress {
    description     = "MySQL from App tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg-${var.environment}"
  }
}

######################
#       RDS          #
######################

resource "aws_db_subnet_group" "db_subnet" {
  name       = "db-subnet-group-${var.environment}"
  subnet_ids = [for subnet in aws_subnet.db_subnets : subnet.id]

  tags = {
    Name = "db-subnet-group-${var.environment}"
  }
}

resource "aws_db_instance" "mysql_db" {
  identifier             = "treetier-db-${var.environment}"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.db_instance_type
  allocated_storage      = 20
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true

  tags = {
    Name = "3tier-rds-${var.environment}"
  }
}
