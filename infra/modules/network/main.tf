data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)

  public_subnets = {
    a = {
      availability_zone = local.availability_zones[0]
      cidr_block        = cidrsubnet(var.vpc_cidr, 8, 0)
    }
    b = {
      availability_zone = local.availability_zones[1]
      cidr_block        = cidrsubnet(var.vpc_cidr, 8, 1)
    }
  }

  app_private_subnets = {
    a = {
      availability_zone = local.availability_zones[0]
      cidr_block        = cidrsubnet(var.vpc_cidr, 8, 10)
    }
    b = {
      availability_zone = local.availability_zones[1]
      cidr_block        = cidrsubnet(var.vpc_cidr, 8, 11)
    }
  }

  db_private_subnets = {
    a = {
      availability_zone = local.availability_zones[0]
      cidr_block        = cidrsubnet(var.vpc_cidr, 8, 20)
    }
    b = {
      availability_zone = local.availability_zones[1]
      cidr_block        = cidrsubnet(var.vpc_cidr, 8, 21)
    }
  }

  nat_gateway_keys = var.high_availability_nat ? toset(["a", "b"]) : toset(["a"])
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name_prefix}-${var.environment}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name_prefix}-${var.environment}-igw"
  }
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name_prefix}-${var.environment}-public-${each.key}"
    Tier = "public"
  }
}

resource "aws_subnet" "app_private" {
  for_each = local.app_private_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name_prefix}-${var.environment}-app-private-${each.key}"
    Tier = "application"
  }
}

resource "aws_subnet" "db_private" {
  for_each = local.db_private_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name_prefix}-${var.environment}-db-private-${each.key}"
    Tier = "database"
  }
}

resource "aws_eip" "nat" {
  for_each = local.nat_gateway_keys

  domain = "vpc"

  tags = {
    Name = "${var.name_prefix}-${var.environment}-nat-eip-${each.key}"
  }
}

resource "aws_nat_gateway" "this" {
  for_each = local.nat_gateway_keys

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  depends_on = [aws_internet_gateway.this]

  tags = {
    Name = "${var.name_prefix}-${var.environment}-nat-${each.key}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.name_prefix}-${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "app_private" {
  for_each = local.app_private_subnets

  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[var.high_availability_nat ? each.key : "a"].id
  }

  tags = {
    Name = "${var.name_prefix}-${var.environment}-app-private-${each.key}-rt"
  }
}

resource "aws_route_table_association" "app_private" {
  for_each = aws_subnet.app_private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.app_private[each.key].id
}

# The database tier intentionally has no default internet route. RDS will use
# these isolated subnets later through an RDS DB subnet group.
resource "aws_route_table" "db_private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name_prefix}-${var.environment}-db-private-rt"
  }
}

resource "aws_route_table_association" "db_private" {
  for_each = aws_subnet.db_private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.db_private.id
}

resource "aws_security_group" "alb" {
  name_prefix            = "${var.name_prefix}-${var.environment}-alb-"
  description            = "Internet-facing ALB security group for CloudOpsTracker ${var.environment}."
  vpc_id                 = aws_vpc.this.id
  revoke_rules_on_delete = true

  ingress {
    description = "HTTP - later redirected to HTTPS by the ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-${var.environment}-alb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "app" {
  name_prefix            = "${var.name_prefix}-${var.environment}-app-"
  description            = "Application EC2 security group for CloudOpsTracker ${var.environment}."
  vpc_id                 = aws_vpc.this.id
  revoke_rules_on_delete = true

  ingress {
    description     = "Application traffic from the ALB only"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Outbound traffic for package updates, AWS APIs and database connections"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-${var.environment}-app-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "database" {
  name_prefix            = "${var.name_prefix}-${var.environment}-db-"
  description            = "RDS SQL Server security group for CloudOpsTracker ${var.environment}."
  vpc_id                 = aws_vpc.this.id
  revoke_rules_on_delete = true

  ingress {
    description     = "SQL Server from the application tier only"
    from_port       = var.database_port
    to_port         = var.database_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-${var.environment}-db-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}
