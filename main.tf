locals {
  east = {
    region = "us-east-2",
    vpc_name = "citi-mrc-poc-east"
    vpc_cidr = "172.20.0.0/22"
  }
  west = {
    region = "ca-central-1",
    vpc_name = "citi-mrc-poc-west"
    vpc_cidr = "172.24.0.0/22"
  }
  central = {
    region = "us-east-2",
    vpc_name = "citi-mrc-poc-central"
    vpc_cidr = "172.26.0.0/22"
  }
}

data "aws_caller_identity" "central-peer" {
  provider = aws.aws-central
}
data "aws_caller_identity" "east-peer" {
  provider = aws.aws-east
}
data "aws_caller_identity" "west-peer" {
  provider = aws.aws-west
}


resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp-east" {
  provider = aws.aws-east
  key_name   = "citi-mrc-east" 
  public_key = tls_private_key.pk.public_key_openssh

  provisioner "local-exec" { 
    command = "echo '${tls_private_key.pk.private_key_pem}' > ./secrets/citi-mrc-east.pem"
  }
}

resource "aws_key_pair" "kp-west" {
  provider = aws.aws-west
  key_name   = "citi-mrc-west" 
  public_key = tls_private_key.pk.public_key_openssh

  provisioner "local-exec" { 
    command = "echo '${tls_private_key.pk.private_key_pem}' > ./secrets/citi-mrc-west.pem"
  }
}

resource "aws_key_pair" "kp-central" {
  provider = aws.aws-central
  key_name   = "citi-mrc-central" 
  public_key = tls_private_key.pk.public_key_openssh

  provisioner "local-exec" { # Create "myKey.pem" to your computer!!
    command = "echo '${tls_private_key.pk.private_key_pem}' > ./secrets/citi-mrc-central.pem"
  }
}

module "k8s-east" {
  source = "./k8s"
  cluster_name = "citi-east"
  cluster_region = local.east.region
  cluster_nodes = 3
  cluster_node_type = "m6i.large"
  vpc_cidr = local.east.vpc_cidr
  vpc_name = local.east.vpc_name
  aws_api_key = var.aws_api_key
  aws_api_secret = var.aws_api_secret
  aws_ssh_key = aws_key_pair.kp-east.key_name
  confluent_k8s_namespace = "east"
  mrc_vpc_cidrs = [local.central.vpc_cidr, local.west.vpc_cidr]
}

module "k8s-west" {
  source = "./k8s"
  cluster_name = "citi-west"
  cluster_region = local.west.region
  cluster_nodes = 3
  cluster_node_type = "m6i.large"
  vpc_cidr = local.west.vpc_cidr
  vpc_name = local.west.vpc_name
  aws_api_key = var.aws_api_key
  aws_api_secret = var.aws_api_secret
  aws_ssh_key = aws_key_pair.kp-west.key_name
  confluent_k8s_namespace = "west"
  mrc_vpc_cidrs = [local.central.vpc_cidr, local.east.vpc_cidr]
}

module "k8s-central" {
  source = "./k8s"
  cluster_name = "citi-central"
  cluster_region = local.central.region
  cluster_nodes = 3
  cluster_node_type = "m6i.large"
  vpc_cidr = local.central.vpc_cidr
  vpc_name = local.central.vpc_name
  aws_api_key = var.aws_api_key
  aws_api_secret = var.aws_api_secret
  aws_ssh_key = aws_key_pair.kp-central.key_name
  confluent_k8s_namespace = "central"
  mrc_vpc_cidrs = [local.east.vpc_cidr, local.west.vpc_cidr]
}

########################################## East West Peering ################################

module "east-west-peer" {
  source  = "grem11n/vpc-peering/aws"
  version = "6.0.0"
  providers = {
    aws.this = aws.aws-east
    aws.peer = aws.aws-west
  }
  this_vpc_id = module.k8s-east.vpc_id
  peer_vpc_id = module.k8s-west.vpc_id

  auto_accept_peering        = true
  this_dns_resolution        = true
  peer_dns_resolution        = true

  tags = {
    Name        = "east-west-citi-mrc-vpc-peering"
    Environment = "dev"
    Kind        = "POC"
    Terraform   = "True"
  }

}

# ########################################## West Central Peering ################################

module "west-central-peer" {
  source  = "grem11n/vpc-peering/aws"
  version = "6.0.0"
  providers = {
    aws.this = aws.aws-west
    aws.peer = aws.aws-central
  }
  this_vpc_id = module.k8s-west.vpc_id
  peer_vpc_id = module.k8s-central.vpc_id

  auto_accept_peering        = true
  this_dns_resolution        = true
  peer_dns_resolution        = true

  tags = {
    Name        = "west-central-citi-mrc-vpc-peering"
    Environment = "dev"
    Kind        = "POC"
    Terraform   = "True"
  }
}

# # ########################################## Central East Peering ################################

module "central-east-peer" {
  source  = "grem11n/vpc-peering/aws"
  version = "6.0.0"
  providers = {
    aws.this = aws.aws-central
    aws.peer = aws.aws-east
  }
  this_vpc_id = module.k8s-central.vpc_id
  peer_vpc_id = module.k8s-east.vpc_id

  auto_accept_peering        = true
  this_dns_resolution        = true
  peer_dns_resolution        = true

  tags = {
    Name        = "central-east-citi-mrc-vpc-peering"
    Environment = "dev"
    Kind        = "POC"
    Terraform   = "True"
  }  
}

# # ########################################## Private Hosted Zone ################################

resource "aws_route53_zone" "default" {
  name = "mydomain.com"

  vpc {
    vpc_id = module.k8s-central.vpc_id
    vpc_region = local.central.region
  }
  vpc {
    vpc_id = module.k8s-east.vpc_id
    vpc_region = local.east.region
  }
  vpc {
    vpc_id = module.k8s-west.vpc_id
    vpc_region = local.west.region
  }
}

data "aws_lb" "east-kakfa-0" {
  provider = aws.aws-east
  tags = {
    "elbv2.k8s.aws/cluster" = "citi-east"
    "service.k8s.aws/stack" = "east/kafka-0-lb"
  }
}

data "aws_lb" "east-kakfa-1" {
  provider = aws.aws-east
  tags = {
    "elbv2.k8s.aws/cluster" = "citi-east"
    "service.k8s.aws/stack" = "east/kafka-1-lb"
  }
}

data "aws_lb" "east-kakfa-lb" {
  provider = aws.aws-east
  tags = {
    "elbv2.k8s.aws/cluster" = "citi-east"
    "service.k8s.aws/stack" = "east/kafka-bootstrap-lb"
  }
}

data "aws_lb" "west-kakfa-0" {
  provider = aws.aws-west
  tags = {
    "elbv2.k8s.aws/cluster" = "citi-west"
    "service.k8s.aws/stack" = "west/kafka-0-lb"
  }
}

data "aws_lb" "west-kakfa-1" {
  provider = aws.aws-west
  tags = {
    "elbv2.k8s.aws/cluster" = "citi-west"
    "service.k8s.aws/stack" = "west/kafka-1-lb"
  }
}

data "aws_lb" "west-kakfa-lb" {
  provider = aws.aws-west
  tags = {
    "elbv2.k8s.aws/cluster" = "citi-west"
    "service.k8s.aws/stack" = "west/kafka-bootstrap-lb"
  }
}

data "aws_lb" "central-kakfa-0" {
  provider = aws.aws-central
  tags = {
    "elbv2.k8s.aws/cluster" = "citi-central"
    "service.k8s.aws/stack" = "central/kafka-0-lb"
  }
}

data "aws_lb" "central-kakfa-1" {
  provider = aws.aws-central
  tags = {
    "elbv2.k8s.aws/cluster" = "citi-central"
    "service.k8s.aws/stack" = "central/kafka-1-lb"
  }
}

data "aws_lb" "central-kakfa-lb" {
  provider = aws.aws-central
  tags = {
    "elbv2.k8s.aws/cluster" = "citi-central"
    "service.k8s.aws/stack" = "central/kafka-bootstrap-lb"
  }
}

data "aws_lb" "central-controlcenter-lb" {
  provider = aws.aws-central
  tags = {
    "elbv2.k8s.aws/cluster" = "citi-central"
    "service.k8s.aws/stack" = "central/controlcenter-bootstrap-lb"
  }
}

data "aws_lb" "cp-ingress" {
  name = "cp-ingress"
}

## Bastion Host 

resource "aws_key_pair" "bastion-host" {
  provider = aws.aws-east
  key_name   = "citi-mrc-bastion" 
  public_key = tls_private_key.pk.public_key_openssh

  provisioner "local-exec" { 
    command = "echo '${tls_private_key.pk.private_key_pem}' > ./secrets/citi-mrc-bastion.pem"
  }
}

module "bastion_host" {
  providers = {
    aws = aws.aws-central
  }
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "citi-mrc-poc-bastion"

  ami                    = "ami-060b1c20c93e475fd"
  instance_type          = "t3.large"
  key_name               = aws_key_pair.bastion-host.key_name
  monitoring             = true
  vpc_security_group_ids = [module.k8s-central.default_security_group_id]
  subnet_id              = module.k8s-central.public_subnet_cidr[0]
  associate_public_ip_address = true

  tags = {
    Terraform   = "true"
    Environment = "ops"
    Owner = "Shiv"
    Purpose = "citi-mrc-setup"
  }
}

module "bastion_host_linux" {
  providers = {
    aws = aws.aws-central
  }
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "citi-mrc-poc-bastion-linux"

  ami                    = "ami-024e6efaf93d85776"
  instance_type          = "t3.large"
  key_name               = aws_key_pair.bastion-host.key_name
  monitoring             = true
  vpc_security_group_ids = [module.k8s-central.default_security_group_id]
  subnet_id              = module.k8s-central.public_subnet_cidr[0]
  associate_public_ip_address = true

  tags = {
    Terraform   = "true"
    Environment = "ops"
    Owner = "Shiv"
    Purpose = "citi-mrc-setup"
  }
}