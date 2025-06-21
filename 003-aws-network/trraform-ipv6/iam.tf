# ----------------------------
# IAM Role and Policies
# ----------------------------

# EC2インスタンス用のIAMロール
resource "aws_iam_role" "ec2_role" {
  name = "ec2-s3-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "ec2-s3-role"
  }
}

# S3アクセス用のIAMポリシー
resource "aws_iam_policy" "s3_access_policy" {
  name        = "S3AccessPolicy"
  description = "Policy for S3 access"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}-${data.aws_caller_identity.current.account_id}",
          "arn:aws:s3:::${var.s3_bucket_name}-${data.aws_caller_identity.current.account_id}/*"
        ]
      }
    ]
  })
}

# SSM管理用のポリシーアタッチメント
resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# S3アクセス用のポリシーアタッチメント
resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# EC2インスタンスプロファイル
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-s3-role"
  role = aws_iam_role.ec2_role.name
}