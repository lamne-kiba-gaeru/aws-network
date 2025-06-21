# ----------------------------
# Provider
# ----------------------------
provider "aws" {
  region = var.region
}

# ----------------------------
# Data Sources
# ----------------------------
data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ----------------------------
# S3 Bucket
# ----------------------------
resource "aws_s3_bucket" "demo_bucket" {
  bucket = "${var.s3_bucket_name}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "demo-vpc-endpoint-bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "demo_bucket_access" {
  bucket = aws_s3_bucket.demo_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ----------------------------
# VPC Peering Connection
# ----------------------------
resource "aws_vpc_peering_connection" "vpc_peering" {
  vpc_id      = aws_vpc.multi_az_vpc.id
  peer_vpc_id = aws_vpc.single_az_vpc.id
  auto_accept = true

  tags = {
    Name = "multi-az-to-single-az-peering"
  }
}

# ----------------------------
# VPC Endpoints
# ----------------------------
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id       = aws_vpc.multi_az_vpc.id
  service_name = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [aws_route_table.multi_az_private.id]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Resource  = "*"
      }
    ]
  })
}

resource "aws_security_group" "ssm_endpoint_sg" {
  name        = "ssm-endpoint-sg"
  description = "Security group for SSM VPC Endpoints"
  vpc_id      = aws_vpc.multi_az_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.multi_az_vpc_cidr]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ssm-endpoint-sg"
  }
}

resource "aws_vpc_endpoint" "ssm_endpoint" {
  vpc_id            = aws_vpc.multi_az_vpc.id
  service_name      = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.multi_az_private_a.id, aws_subnet.multi_az_private_c.id]
  security_group_ids = [aws_security_group.ssm_endpoint_sg.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2messages_endpoint" {
  vpc_id            = aws_vpc.multi_az_vpc.id
  service_name      = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.multi_az_private_a.id, aws_subnet.multi_az_private_c.id]
  security_group_ids = [aws_security_group.ssm_endpoint_sg.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssmmessages_endpoint" {
  vpc_id            = aws_vpc.multi_az_vpc.id
  service_name      = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.multi_az_private_a.id, aws_subnet.multi_az_private_c.id]
  security_group_ids = [aws_security_group.ssm_endpoint_sg.id]
  private_dns_enabled = true
}

# ----------------------------
# Security Group for Single AZ VPC
# ----------------------------
resource "aws_security_group" "single_az_sg" {
  name        = "single-az-sg"
  description = "Allow HTTP from MultiAZ VPC"
  vpc_id      = aws_vpc.single_az_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.multi_az_vpc_cidr]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "single-az-sg"
  }
}