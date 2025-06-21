# ----------------------------
# S3 VPC Endpoint for Single AZ VPC
# ----------------------------
resource "aws_vpc_endpoint" "single_az_s3_endpoint" {
  vpc_id            = aws_vpc.single_az_vpc.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.single_az_private.id]

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