# Sample Terraform with misconfigurations
resource "aws_security_group" "web" {
  name = "web-sg"
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # BAD: SSH open to world
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "data" {
  bucket = "my-data-bucket"
  # BAD: No encryption configured
}

resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  key_name      = "my-key"
  
  user_data = <<-EOF
    #!/bin/bash
    export DB_PASSWORD="hardcoded123"  # BAD: Hardcoded secret
  EOF
  
  # BAD: No tags for compliance
}
