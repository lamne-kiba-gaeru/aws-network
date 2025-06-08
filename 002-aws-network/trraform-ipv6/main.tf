# ----------------------------
# Provider
# ----------------------------
# ここら辺はご自身の作業環境に合わせてください
provider "aws" {
  region = "ap-northeast-1"
}

# ----------------------------
# Variables
# ----------------------------
# ここら辺はご自身の作業環境に合わせてください
variable "availability_zone_1" {
  description = "The first availability zone."
  type        = string
  default     = "us-east-1a"
}

variable "availability_zone_2" {
  description = "The second availability zone."
  type        = string
  default     = "us-east-1c"
}

variable "instance_type" {
  description = "The EC2 instance type."
  type        = string
  default     = "t2.micro"
}

variable "latest_ami_id" {
  description = "The latest Amazon Linux 2023 AMI ID from SSM Parameter Store."
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

variable "vpc_cidr_block" {
  description = "The IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/24"
}

variable "public_subnet_a_cidr_block" {
  description = "The IPv4 CIDR block for Public Subnet A."
  type        = string
  default     = "10.0.0.0/27"
}

variable "public_subnet_c_cidr_block" {
  description = "The IPv4 CIDR block for Public Subnet C."
  type        = string
  default     = "10.0.0.32/27"
}

variable "private_subnet_a_cidr_block" {
  description = "The IPv4 CIDR block for Private Subnet A."
  type        = string
  default     = "10.0.0.64/27"
}

variable "private_subnet_c_cidr_block" {
  description = "The IPv4 CIDR block for Private Subnet C."
  type        = string
  default     = "10.0.0.96/27"
}

variable "sg_cidr_block" {
  description = "The IPv4 CIDR block for the security group ingress rule."
  type        = string
  default     = "10.1.2.0/27"
}

### **AWSリソースの定義**
# VPCの作成とIPv6 CIDRブロックの自動割り当て
resource "aws_vpc" "my_vpc" {
  cidr_block              = var.vpc_cidr_block
  enable_dns_support      = true
  enable_dns_hostnames    = true
  assign_generated_ipv6_cidr_block  = true # IPv6 CIDRブロックを自動的に割り当てる

  tags = {
    Name = "vpc-demo"
  }
}

# インターネットゲートウェイ (IGW)
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "igw-demo"
  }
}

# エグレスオンリーインターネットゲートウェイ (EIGW) for IPv6
resource "aws_egress_only_internet_gateway" "egress_only_internet_gateway" {
  vpc_id = aws_vpc.my_vpc.id
}

# パブリックサブネットA
resource "aws_subnet" "public_subnet_a" {
  vpc_id                          = aws_vpc.my_vpc.id
  cidr_block                      = var.public_subnet_a_cidr_block
  availability_zone               = var.availability_zone_1
  assign_ipv6_address_on_creation = true # インスタンス作成時にIPv6アドレスを自動割り当て
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.my_vpc.ipv6_cidr_block, 8, 0)

  tags = {
    Name = "public-subnet-a-demo"
  }
}

# パブリックサブネットC
resource "aws_subnet" "public_subnet_c" {
  vpc_id                          = aws_vpc.my_vpc.id
  cidr_block                      = var.public_subnet_c_cidr_block
  availability_zone               = var.availability_zone_2
  assign_ipv6_address_on_creation = true # インスタンス作成時にIPv6アドレスを自動割り当て
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.my_vpc.ipv6_cidr_block, 8, 1)

  tags = {
    Name = "public-subnet-c-demo"
  }
}

# プライベートサブネットA
resource "aws_subnet" "private_subnet_a" {
  vpc_id                          = aws_vpc.my_vpc.id
  cidr_block                      = var.private_subnet_a_cidr_block
  availability_zone               = var.availability_zone_1
  assign_ipv6_address_on_creation = true # インスタンス作成時にIPv6アドレスを自動割り当て
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.my_vpc.ipv6_cidr_block, 8, 2)

  tags = {
    Name = "private-subnet-a-demo"
  }
}

# プライベートサブネットC
resource "aws_subnet" "private_subnet_c" {
  vpc_id                          = aws_vpc.my_vpc.id
  cidr_block                      = var.private_subnet_c_cidr_block
  availability_zone               = var.availability_zone_2
  assign_ipv6_address_on_creation = true # インスタンス作成時にIPv6アドレスを自動割り当て
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.my_vpc.ipv6_cidr_block, 8, 3)

  tags = {
    Name = "private-subnet-c-demo"
  }
}

# パブリックルートテーブル
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "public-root-tbl"
  }
}

# パブリックルートテーブルのIPv4デフォルトルート (IGWへ)
resource "aws_route" "public_ipv4_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

# パブリックルートテーブルのIPv6デフォルトルート (IGWへ)
resource "aws_route" "public_ipv6_route" {
  route_table_id           = aws_route_table.public_route_table.id
  destination_ipv6_cidr_block = "::/0" # IPv6のデフォルトルート
  gateway_id               = aws_internet_gateway.internet_gateway.id
}

# パブリックサブネットAとルートテーブルの関連付け
resource "aws_route_table_association" "public_subnet_a_route_table_association" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

# パブリックサブネットCとルートテーブルの関連付け
resource "aws_route_table_association" "public_subnet_c_route_table_association" {
  subnet_id      = aws_subnet.public_subnet_c.id
  route_table_id = aws_route_table.public_route_table.id
}

# NATゲートウェイ用のElastic IP (IPv4)
resource "aws_eip" "nat_gateway_eip" {
  vpc = true
}

# パブリックサブネットAにNATゲートウェイを配置 (IPv4)
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public_subnet_a.id

  tags = {
    Name = "nat-gateway-demo"
  }
}

# プライベートルートテーブル
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "private-root-tbl"
  }
}

# プライベートサブネットからNATゲートウェイへのルート (IPv4)
resource "aws_route" "private_ipv4_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}

# プライベートサブネットからEgress-Only IGWへのルート (IPv6)
resource "aws_route" "private_ipv6_route" {
  route_table_id              = aws_route_table.private_route_table.id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.egress_only_internet_gateway.id
}

# プライベートサブネットAとルートテーブルの関連付け
resource "aws_route_table_association" "private_subnet_a_route_table_association" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_route_table.id
}

# プライベートサブネットCとルートテーブルの関連付け
resource "aws_route_table_association" "private_subnet_c_route_table_association" {
  subnet_id      = aws_subnet.private_subnet_c.id
  route_table_id = aws_route_table.private_route_table.id
}

# パブリックセキュリティグループ
resource "aws_security_group" "public_security_group" {
  name        = "public-sg"
  description = "Allow HTTP traffic for IPv4 and IPv6"
  vpc_id      = aws_vpc.my_vpc.id

  # IPv4 イングレスルール
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.sg_cidr_block]
  }

  # IPv6 イングレスルール (ALBからのIPv6トラフィックを許可)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    ipv6_cidr_blocks = ["::/0"] # ALBからのIPv6トラフィックを許可するため追加
  }

  # デフォルトのエグレスルール (全てのトラフィックを許可)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "public-sg"
  }
}

# ALB用セキュリティグループ
resource "aws_security_group" "alb_security_group" {
  name        = "alb-sg"
  description = "Security group for ALB with IPv4 and IPv6 support"
  vpc_id      = aws_vpc.my_vpc.id

  # IPv4 イングレスルール (インターネットからのHTTPトラフィックを許可)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # IPv6 イングレスルール (インターネットからのHTTPトラフィックを許可)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }

  # デフォルトのエグレスルール (全てのトラフィックを許可)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

# プライベートセキュリティグループ
resource "aws_security_group" "private_security_group" {
  name        = "private-sg"
  description = "Allow HTTP traffic from ALB"
  vpc_id      = aws_vpc.my_vpc.id

  # イングレスルール: ALBセキュリティグループからのHTTPトラフィックを許可 (IPv4 & IPv6)
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_security_group.id]
  }

  # デフォルトのエグレスルール (全てのトラフィックを許可)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "private-sg"
  }
}

# SSM Parameter StoreからAMI IDを取得
data "aws_ssm_parameter" "ami_id" {
  name = var.latest_ami_id
}

# EC2インスタンスA
resource "aws_instance" "ec2_instance_a" {
  instance_type          = var.instance_type
  ami                    = data.aws_ssm_parameter.ami_id.value
  subnet_id              = aws_subnet.private_subnet_a.id
  vpc_security_group_ids = [aws_security_group.private_security_group.id]
  user_data = base64encode(<<EOF
#!/bin/bash
dnf install -y httpd
echo "<h1>Hello from Private Subnet A</h1>" > /var/www/html/index.html
systemctl start httpd
systemctl enable httpd
EOF
  )

  tags = {
    Name = "ec2-private-a"
  }
}

# EC2インスタンスC
resource "aws_instance" "ec2_instance_c" {
  instance_type          = var.instance_type
  ami                    = data.aws_ssm_parameter.ami_id.value
  subnet_id              = aws_subnet.private_subnet_c.id
  vpc_security_group_ids = [aws_security_group.private_security_group.id]
  user_data = base64encode(<<EOF
#!/bin/bash -xe
dnf install -y httpd
echo "<h1>Hello from Private Subnet C</h1>" > /var/www/html/index.html
systemctl start httpd
systemctl enable httpd
EOF
  )

  tags = {
    Name = "ec2-private-c"
  }
}

# IPv6対応ALBの作成
resource "aws_lb" "application_load_balancer" {
  name               = "demo-alb"
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "dualstack" # IPv4とIPv6の両方に対応
  security_groups    = [aws_security_group.alb_security_group.id]
  subnets = [
    aws_subnet.public_subnet_a.id,
    aws_subnet.public_subnet_c.id
  ]

  tags = {
    Name = "demo-alb"
  }
}

# ALBのターゲットグループ
resource "aws_lb_target_group" "alb_target_group" {
  name     = "demo-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  health_check {
    path     = "/"
    protocol = "HTTP"
  }

  target_type     = "instance"
  ip_address_type = "ipv4" # EC2インスタンスはIPv4で登録されるため

  tags = {
    Name = "demo-tg"
  }
}

# EC2インスタンスAをターゲットグループにアタッチ
resource "aws_lb_target_group_attachment" "ec2_instance_a_attachment" {
  target_group_arn = aws_lb_target_group.alb_target_group.arn
  target_id        = aws_instance.ec2_instance_a.id
  port             = 80
}

# EC2インスタンスCをターゲットグループにアタッチ
resource "aws_lb_target_group_attachment" "ec2_instance_c_attachment" {
  target_group_arn = aws_lb_target_group.alb_target_group.arn
  target_id        = aws_instance.ec2_instance_c.id
  port             = 80
}

# ALBリスナー
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

### **出力値の定義**
output "load_balancer_dns" {
  description = "DNS Name of the Application Load Balancer"
  value       = aws_lb.application_load_balancer.dns_name
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.my_vpc.id
}

output "vpc_ipv6_cidr_block" {
  description = "IPv6 CIDR Block assigned to the VPC"
  value       = aws_vpc.my_vpc.ipv6_cidr_block
}

