# --- VPC ---
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "3tier-vpc-${var.environment}"
  }
}

# --- Subnets ---
resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidr)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr[count.index]
  map_public_ip_on_launch = true

  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "3tier-public-subnet-${count.index}-${var.environment}"
  }
}

resource "aws_subnet" "private_subnets" {
  count                   = length(var.private_subnet_cidr)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidr[count.index]
  map_public_ip_on_launch = false

  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "3tier-private-subnet-${count.index}-${var.environment}"
  }
}

resource "aws_subnet" "db_subnets" {
  count                   = length(var.db_subnet_cidr)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.db_subnet_cidr[count.index]
  map_public_ip_on_launch = false

  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "3tier-db-subnet-${count.index}-${var.environment}"
  }
}

# Data source for AZs (to spread subnets across availability zones)
data "aws_availability_zones" "available" {
  state = "available"
}

# --- Internet Gateway ---
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "3tier-igw-${var.environment}"
  }
}

# --- Public Route Table ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "3tier-public-rt-${var.environment}"
  }
}

resource "aws_route" "public-route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_association" {
  count          = length(var.public_subnet_cidr)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- NAT Gateway (for private and DB subnets to have outbound internet) ---
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = {
    Name = "3tier-natgw-${var.environment}"
  }
}

# --- Private Route Table ---
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "3tier-private-rt-${var.environment}"
  }
}

resource "aws_route" "private-route" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.natgw.id
}

resource "aws_route_table_association" "private_association" {
  count          = length(var.private_subnet_cidr)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private.id
}

# --- Database Route Table ---
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "3tier-db-rt-${var.environment}"
  }
}

# Because DB subnets usually only need internal connectivity, we typically route
# traffic to the NAT Gateway for OS updates, etc. We won't set an IGW route.
resource "aws_route" "db-route" {
  route_table_id         = aws_route_table.db.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.natgw.id
}

resource "aws_route_table_association" "db_association" {
  count          = length(var.db_subnet_cidr)
  subnet_id      = aws_subnet.db_subnets[count.index].id
  route_table_id = aws_route_table.db.id
}
