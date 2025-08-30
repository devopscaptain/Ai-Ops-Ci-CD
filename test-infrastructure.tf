# Test infrastructure with security issues
resource "aws_security_group" "web_server" {
  name        = "web-server-sg"
  description = "Security group for web server"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # CRITICAL: SSH open to world
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # CRITICAL: Database port open to world
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "app_data" {
  bucket = "my-app-data-bucket-${random_id.bucket.hex}"
  # MEDIUM: No encryption configured
}

resource "aws_instance" "web" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t3.micro"
  
  vpc_security_group_ids = [aws_security_group.web_server.id]
  
  user_data = <<-EOF
    #!/bin/bash
    export DB_PASSWORD="supersecret123"  # HIGH: Hardcoded password
    export API_KEY="sk-1234567890abcdef"  # HIGH: Hardcoded API key
    
    # Install application
    yum update -y
    yum install -y httpd
    systemctl start httpd
  EOF
  
  # MEDIUM: No tags for compliance tracking
}

resource "aws_db_instance" "main" {
  identifier = "main-database"
  
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  
  allocated_storage = 20
  
  db_name  = "appdb"
  username = "admin"
  password = "password123"  # CRITICAL: Hardcoded database password
  
  vpc_security_group_ids = [aws_security_group.web_server.id]
  
  skip_final_snapshot = true
  # MEDIUM: No encryption at rest
  # MEDIUM: No backup retention configured
}

resource "random_id" "bucket" {
  byte_length = 4
}
