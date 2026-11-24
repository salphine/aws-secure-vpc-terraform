provider "aws" {
  region = var.aws_region
}

# 1. The VPC
resource "aws_vpc" "secure_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Secure-VPC"
  }
}

# 2. Public Subnet (for the Bastion Host)
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.secure_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "Public-Subnet"
  }
}

# 3. Private Subnet (for the internal server)
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.secure_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "Private-Subnet"
  }
}

# 4. Internet Gateway (for the public subnet)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.secure_vpc.id
}

# 5. Public Route Table (Routes traffic to the Internet)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.secure_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public-Route-Table"
  }
}

# 6. Associate Public Subnet with Public Route Table
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 7. Public Security Group (Allows SSH from YOUR IP only)
resource "aws_security_group" "public_sg" {
  name        = "public-bastion-sg"
  description = "Allow SSH from my IP"
  vpc_id      = aws_vpc.secure_vpc.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["197.248.31.197/32"]
  }
}

# 8. Private Security Group (Allows SSH ONLY from the Public Security Group)
resource "aws_security_group" "private_sg" {
  name        = "private-instance-sg"
  description = "Allow SSH only from Bastion"
  vpc_id      = aws_vpc.secure_vpc.id

  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 9. Lock down the Default Security Group (Bonus Security Fix)
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.secure_vpc.id
  tags = {
    Name = "Default-SG-Locked"
  }
}
# 10. VPC Flow Logs (Security Auditing)
resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.flow_log_group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.secure_vpc.id
}

# 11. CloudWatch Log Group for Flow Logs
resource "aws_cloudwatch_log_group" "flow_log_group" {
  name = "vpc-flow-log-group"
}

# 12. IAM Role for Flow Logs
resource "aws_iam_role" "flow_log_role" {
  name = "vpc-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

# 13. IAM Policy for Flow Logs
resource "aws_iam_role_policy" "flow_log_policy" {
  name = "vpc-flow-log-policy"
  role = aws_iam_role.flow_log_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
