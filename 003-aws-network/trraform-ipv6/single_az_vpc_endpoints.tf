# ----------------------------
# SSM VPC Endpoints for Single AZ VPC
# ----------------------------
resource "aws_security_group" "single_az_ssm_endpoint_sg" {
  name        = "single-az-ssm-endpoint-sg"
  description = "Security group for SSM VPC Endpoints in Single AZ VPC"
  vpc_id      = aws_vpc.single_az_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.single_az_vpc_cidr]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    ipv6_cidr_blocks = [aws_vpc.single_az_vpc.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "single-az-ssm-endpoint-sg"
  }
}

resource "aws_vpc_endpoint" "single_az_ssm_endpoint" {
  vpc_id            = aws_vpc.single_az_vpc.id
  service_name      = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.single_az_private.id]
  security_group_ids = [aws_security_group.single_az_ssm_endpoint_sg.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "single_az_ec2messages_endpoint" {
  vpc_id            = aws_vpc.single_az_vpc.id
  service_name      = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.single_az_private.id]
  security_group_ids = [aws_security_group.single_az_ssm_endpoint_sg.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "single_az_ssmmessages_endpoint" {
  vpc_id            = aws_vpc.single_az_vpc.id
  service_name      = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.single_az_private.id]
  security_group_ids = [aws_security_group.single_az_ssm_endpoint_sg.id]
  private_dns_enabled = true
}