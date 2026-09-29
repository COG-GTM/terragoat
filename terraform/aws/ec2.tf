resource "aws_instance" "web_host" {
  # ec2 have plain text secrets in user data
  ami           = "${var.ami}"
  instance_type = "t2.nano"

  vpc_security_group_ids = [
  "${aws_security_group.web-node.id}"]
  subnet_id = "${aws_subnet.web_private_subnet.id}"
  user_data = <<EOF
#! /bin/bash
sudo apt-get update
sudo apt-get install -y apache2
sudo systemctl start apache2
sudo systemctl enable apache2
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMAAA
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=us-west-2
echo "<h1>Deployed via Terraform</h1>" | sudo tee /var/www/html/index.html
EOF
  tags = merge({
    Name = "${local.resource_prefix.value}-ec2"
    }, {
    git_commit           = "d68d2897add9bc2203a5ed0632a5cdd8ff8cefb0"
    git_file             = "terraform/aws/ec2.tf"
    git_last_modified_at = "2020-06-16 14:46:24"
    git_last_modified_by = "nimrodkor@gmail.com"
    git_modifiers        = "nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "347af3cd-4f70-4632-aca3-4d5e30ffc0b6"
  })
}

resource "aws_ebs_volume" "web_host_storage" {
  # unencrypted volume
  availability_zone = "${var.region}a"
  #encrypted         = false  # Setting this causes the volume to be recreated on apply 
  size = 1
  tags = merge({
    Name = "${local.resource_prefix.value}-ebs"
    }, {
    git_commit           = "d3439f0f2af62f6fa3521e14d6c27819ef8f12e1"
    git_file             = "terraform/aws/ec2.tf"
    git_last_modified_at = "2021-05-02 11:17:26"
    git_last_modified_by = "nimrodkor@users.noreply.github.com"
    git_modifiers        = "nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "c5509daf-10f0-46af-9e03-41989212521d"
  })
}

resource "aws_ebs_snapshot" "example_snapshot" {
  # ebs snapshot without encryption
  volume_id   = "${aws_ebs_volume.web_host_storage.id}"
  description = "${local.resource_prefix.value}-ebs-snapshot"
  tags = merge({
    Name = "${local.resource_prefix.value}-ebs-snapshot"
    }, {
    git_commit           = "d68d2897add9bc2203a5ed0632a5cdd8ff8cefb0"
    git_file             = "terraform/aws/ec2.tf"
    git_last_modified_at = "2020-06-16 14:46:24"
    git_last_modified_by = "nimrodkor@gmail.com"
    git_modifiers        = "nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "c1008080-ec2f-4512-a0d0-2e9330aa58f0"
  })
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.web_host_storage.id}"
  instance_id = "${aws_instance.web_host.id}"
}

resource "aws_security_group" "web-node" {
  name        = "${local.resource_prefix.value}-sg"
  description = "${local.resource_prefix.value} web tier instances"
  vpc_id      = aws_vpc.web_vpc.id

  depends_on = [aws_vpc.web_vpc]
  tags = {
    git_commit           = "d68d2897add9bc2203a5ed0632a5cdd8ff8cefb0"
    git_file             = "terraform/aws/ec2.tf"
    git_last_modified_at = "2020-06-16 14:46:24"
    git_last_modified_by = "nimrodkor@gmail.com"
    git_modifiers        = "nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "b7af1b40-64eb-4519-a1a0-ab198db4b193"
  }
}

resource "aws_security_group_rule" "web_node_ingress_from_elb" {
  type                     = "ingress"
  description              = "App traffic from the web ELB"
  from_port                = 8000
  to_port                  = 8000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.weblb.id
  security_group_id        = aws_security_group.web-node.id
}

resource "aws_security_group_rule" "web_node_ingress_ssh" {
  type              = "ingress"
  description       = "SSH from within the VPC (bastion/VPN)"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.web_vpc.cidr_block]
  security_group_id = aws_security_group.web-node.id
}

resource "aws_security_group_rule" "web_node_egress_https" {
  type              = "egress"
  description       = "HTTPS egress via NAT for package repos and AWS APIs"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web-node.id
}

resource "aws_security_group_rule" "web_node_egress_http" {
  type              = "egress"
  description       = "HTTP egress via NAT for package repos"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web-node.id
}

resource "aws_security_group_rule" "web_node_egress_mysql" {
  type                     = "egress"
  description              = "MySQL to the RDS instance"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.default.id
  security_group_id        = aws_security_group.web-node.id
}

resource "aws_security_group" "weblb" {
  name        = "${local.resource_prefix.value}-elb-sg"
  description = "${local.resource_prefix.value} web ELB"
  vpc_id      = aws_vpc.web_vpc.id

  tags = {
    Name = "${local.resource_prefix.value}-elb-sg"
  }
}

resource "aws_security_group_rule" "weblb_ingress_http" {
  type              = "ingress"
  description       = "HTTP from trusted networks"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.trusted_cidr_blocks
  security_group_id = aws_security_group.weblb.id
}

resource "aws_security_group_rule" "weblb_egress_to_web_node" {
  type                     = "egress"
  description              = "Forward to web tier instances"
  from_port                = 8000
  to_port                  = 8000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web-node.id
  security_group_id        = aws_security_group.weblb.id
}

resource "aws_vpc" "web_vpc" {
  cidr_block           = "172.16.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge({
    Name = "${local.resource_prefix.value}-vpc"
    }, {
    git_commit           = "d68d2897add9bc2203a5ed0632a5cdd8ff8cefb0"
    git_file             = "terraform/aws/ec2.tf"
    git_last_modified_at = "2020-06-16 14:46:24"
    git_last_modified_by = "nimrodkor@gmail.com"
    git_modifiers        = "nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "9bf2359b-952e-4570-9595-52eba4c20473"
  })
}

resource "aws_default_security_group" "web_vpc_default" {
  vpc_id = aws_vpc.web_vpc.id

  tags = {
    Name = "${local.resource_prefix.value}-default-sg"
  }
}

resource "aws_subnet" "web_subnet" {
  vpc_id                  = aws_vpc.web_vpc.id
  cidr_block              = "172.16.10.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = false

  tags = merge({
    Name = "${local.resource_prefix.value}-subnet"
    }, {
    git_commit           = "6e62522d2ab8f63740e53752b84a6e99cd65696a"
    git_file             = "terraform/aws/ec2.tf"
    git_last_modified_at = "2021-05-02 11:16:31"
    git_last_modified_by = "nimrodkor@gmail.com"
    git_modifiers        = "nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "0345f650-d280-4ca8-86c9-c71c38c0eda8"
  })
}

resource "aws_subnet" "web_subnet2" {
  vpc_id                  = aws_vpc.web_vpc.id
  cidr_block              = "172.16.11.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = false

  tags = merge({
    Name = "${local.resource_prefix.value}-subnet2"
    }, {
    git_commit           = "6e62522d2ab8f63740e53752b84a6e99cd65696a"
    git_file             = "terraform/aws/ec2.tf"
    git_last_modified_at = "2021-05-02 11:16:31"
    git_last_modified_by = "nimrodkor@gmail.com"
    git_modifiers        = "nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "224af03a-00e0-4981-be30-14965833c2db"
  })
}

resource "aws_subnet" "web_private_subnet" {
  vpc_id                  = aws_vpc.web_vpc.id
  cidr_block              = "172.16.20.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.resource_prefix.value}-private-subnet"
  }
}

resource "aws_subnet" "web_private_subnet2" {
  vpc_id                  = aws_vpc.web_vpc.id
  cidr_block              = "172.16.21.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.resource_prefix.value}-private-subnet2"
  }
}

resource "aws_internet_gateway" "web_igw" {
  vpc_id = aws_vpc.web_vpc.id

  tags = merge({
    Name = "${local.resource_prefix.value}-igw"
    }, {
    git_commit           = "d68d2897add9bc2203a5ed0632a5cdd8ff8cefb0"
    git_file             = "terraform/aws/ec2.tf"
    git_last_modified_at = "2020-06-16 14:46:24"
    git_last_modified_by = "nimrodkor@gmail.com"
    git_modifiers        = "nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "d8e63cb4-2fb5-4726-9c86-5fd05ef03674"
  })
}

resource "aws_route_table" "web_rtb" {
  vpc_id = aws_vpc.web_vpc.id

  tags = merge({
    Name = "${local.resource_prefix.value}-rtb"
    }, {
    git_commit           = "d68d2897add9bc2203a5ed0632a5cdd8ff8cefb0"
    git_file             = "terraform/aws/ec2.tf"
    git_last_modified_at = "2020-06-16 14:46:24"
    git_last_modified_by = "nimrodkor@gmail.com"
    git_modifiers        = "nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "5e4fee6e-a6aa-4b61-a741-47c5efb463e1"
  })
}

resource "aws_route_table_association" "rtbassoc" {
  subnet_id      = aws_subnet.web_subnet.id
  route_table_id = aws_route_table.web_rtb.id
}

resource "aws_route_table_association" "rtbassoc2" {
  subnet_id      = aws_subnet.web_subnet2.id
  route_table_id = aws_route_table.web_rtb.id
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.web_rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.web_igw.id

  timeouts {
    create = "5m"
  }
}

resource "aws_eip" "web_nat" {
  domain = "vpc"

  tags = {
    Name = "${local.resource_prefix.value}-nat-eip"
  }
}

resource "aws_nat_gateway" "web_nat" {
  allocation_id = aws_eip.web_nat.id
  subnet_id     = aws_subnet.web_subnet.id

  tags = {
    Name = "${local.resource_prefix.value}-nat"
  }

  depends_on = [aws_internet_gateway.web_igw]
}

resource "aws_route_table" "web_private_rtb" {
  vpc_id = aws_vpc.web_vpc.id

  tags = {
    Name = "${local.resource_prefix.value}-private-rtb"
  }
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.web_private_rtb.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.web_nat.id
}

resource "aws_route_table_association" "private_rtbassoc" {
  subnet_id      = aws_subnet.web_private_subnet.id
  route_table_id = aws_route_table.web_private_rtb.id
}

resource "aws_route_table_association" "private_rtbassoc2" {
  subnet_id      = aws_subnet.web_private_subnet2.id
  route_table_id = aws_route_table.web_private_rtb.id
}


resource "aws_network_interface" "web-eni" {
  subnet_id   = aws_subnet.web_subnet.id
  private_ips = ["172.16.10.100"]

  tags = merge({
    Name = "${local.resource_prefix.value}-primary_network_interface"
    }, {
    git_commit           = "d68d2897add9bc2203a5ed0632a5cdd8ff8cefb0"
    git_file             = "terraform/aws/ec2.tf"
    git_last_modified_at = "2020-06-16 14:46:24"
    git_last_modified_by = "nimrodkor@gmail.com"
    git_modifiers        = "nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "7e2ffea8-739f-467d-b57b-53cbc0d7ccbe"
  })
}

# VPC Flow Logs to S3
resource "aws_flow_log" "vpcflowlogs" {
  log_destination      = aws_s3_bucket.flowbucket.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.web_vpc.id

  tags = merge({
    Name        = "${local.resource_prefix.value}-flowlogs"
    Environment = local.resource_prefix.value
    }, {
    git_commit           = "d68d2897add9bc2203a5ed0632a5cdd8ff8cefb0"
    git_file             = "terraform/aws/ec2.tf"
    git_last_modified_at = "2020-06-16 14:46:24"
    git_last_modified_by = "nimrodkor@gmail.com"
    git_modifiers        = "nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "6808d4b7-45bc-4d1d-9523-96757a3add3a"
  })
}

resource "aws_s3_bucket" "flowbucket" {
  bucket        = "${local.resource_prefix.value}-flowlogs"
  force_destroy = true

  tags = merge({
    Name        = "${local.resource_prefix.value}-flowlogs"
    Environment = local.resource_prefix.value
    }, {
    git_commit           = "d68d2897add9bc2203a5ed0632a5cdd8ff8cefb0"
    git_file             = "terraform/aws/ec2.tf"
    git_last_modified_at = "2020-06-16 14:46:24"
    git_last_modified_by = "nimrodkor@gmail.com"
    git_modifiers        = "nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "f058838a-b1e0-4383-b965-7e06e987ffb1"
  })
}

output "ec2_private_dns" {
  description = "Web Host private DNS name"
  value       = aws_instance.web_host.private_dns
}

output "weblb_dns_name" {
  description = "Web ELB DNS name"
  value       = aws_elb.weblb.dns_name
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.web_vpc.id
}

output "public_subnet" {
  description = "The ID of the Public subnet"
  value       = aws_subnet.web_subnet.id
}

output "public_subnet2" {
  description = "The ID of the Public subnet"
  value       = aws_subnet.web_subnet2.id
}

output "private_subnet" {
  description = "The ID of the private subnet"
  value       = aws_subnet.web_private_subnet.id
}

output "private_subnet2" {
  description = "The ID of the private subnet"
  value       = aws_subnet.web_private_subnet2.id
}
