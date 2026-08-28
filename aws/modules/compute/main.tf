locals {
  common_tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managed_by  = "opentofu"
  })

  # D-28: AMI resolution — user override or data source lookup
  ami_id = var.image_id != null ? var.image_id : data.aws_ami.ubuntu.id
}

# D-28: Latest Ubuntu 22.04 from Canonical (region-specific, not backend-dependent)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# D-32: Cloud-native SSH key injection via aws_key_pair
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project}-${var.environment}-key"
  public_key = var.public_key_openssh
  tags       = local.common_tags
}

resource "aws_instance" "main" {
  ami                    = local.ami_id
  instance_type          = var.size
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = aws_key_pair.deployer.key_name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-instance"
  })

  lifecycle {
    prevent_destroy = true
  }
}
