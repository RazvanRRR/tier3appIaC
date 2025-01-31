environment = "dev-minimal"

# VPC CIDRs (keep them as-is or adjust as needed)
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidr = ["10.0.3.0/24", "10.0.4.0/24"]
db_subnet_cidr      = ["10.0.5.0/24", "10.0.6.0/24"]

# Use a small key pair you already have
aws_key_name = "razvankey"

# Switch to small instance types
app_instance_type = "t3.micro"
db_instance_type  = "db.t3.micro"

# Keep the database name, user, etc. 
db_name     = "myappdb"
db_username = "admin"
db_password = "CloudSecure"

# Auto Scaling Group capacity for minimal cost
app_asg_min_size         = 1
app_asg_max_size         = 1
app_asg_desired_capacity = 1
