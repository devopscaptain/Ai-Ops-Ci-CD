# Test file with intentional security issues
resource "aws_security_group" "web" {
  name = "web-sg"
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # CRITICAL: SSH open to world
  }
  
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # CRITICAL: Database open to world
  }
}

resource "aws_s3_bucket" "data" {
  bucket = "my-company-data-${random_id.bucket.hex}"
  # MEDIUM: No encryption configured
}

resource "aws_db_instance" "main" {
  engine         = "mysql"
  instance_class = "db.t3.micro"
  username       = "admin"
  password       = "password123"  # HIGH: Hardcoded password
  
  skip_final_snapshot = true
  # MEDIUM: No encryption at rest
}

resource "aws_iam_role_policy" "admin" {
  name = "admin-policy"
  role = aws_iam_role.app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "*"           # CRITICAL: Full admin access
      Resource = "*"
    }]
  })
}
