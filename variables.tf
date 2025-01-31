variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidr" {
  type    = list(string)
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "db_subnet_cidr" {
  type    = list(string)
  default = ["10.0.5.0/24", "10.0.6.0/24"]
}

variable "aws_key_name" {
  type        = string
  description = "AWS key pair name to associate with EC2 instances"
  default     = "razvankey"
}

variable "app_instance_type" {
  type    = string
  default = "t2.micro"
}

variable "db_instance_type" {
  type    = string
  default = "db.t2.micro"
}

variable "db_name" {
  type    = string
  default = "myappdb"
}

variable "db_username" {
  type    = string
  default = "admin"
}

variable "db_password" {
  type    = string
  default = "Cloudpassword123"
}

variable "environment" {
  type    = string
  default = "dev"
}
variable "app_asg_min_size" {
  type    = number
  default = 1
}

variable "app_asg_max_size" {
  type    = number
  default = 2
}

variable "app_asg_desired_capacity" {
  type    = number
  default = 1
}
