##################################### AWS NETWORK SETUP #########################################
data "aws_region" "current" {
  name = var.cluster_region
}

data "aws_availability_zones" "available" {
}

locals {
    eks_cidr = var.vpc_cidr
    eks_vpc_partition = cidrsubnets(local.eks_cidr, 2, 2)
    eks_vpc_public_partition = cidrsubnets(local.eks_vpc_partition[0], 2, 2)
    eks_vpc = {
        private_subnets = cidrsubnets(local.eks_vpc_partition[1], 2, 2)
        public_subnets  = cidrsubnets(local.eks_vpc_partition[0], 2, 2)
        # database_subnets = cidrsubnets(local.eks_vpc_public_partition[0], 2, 2)
        azs             = formatlist("${data.aws_region.current.name}%s", ["a", "b"])
    }
}

module "ops-vpc" {
  source            = "terraform-aws-modules/vpc/aws"
  name              = var.vpc_name
  azs               = local.eks_vpc.azs
  cidr              = local.eks_cidr
  private_subnets   = local.eks_vpc.private_subnets
  public_subnets    = local.eks_vpc.public_subnets
  enable_nat_gateway = true
  single_nat_gateway = true
  one_nat_gateway_per_az = false
  flow_log_file_format = "plain-text"
  public_subnet_tags = {
   "kubernetes.io/cluster/${local.eks_cluster_name}" = "owned"
   "kubernetes.io/role/elb" = 1
   "kubernetes.io/role/internal-elb" = 1
  }
  tags = {
    Terraform = "true"
    Environment = "${var.vpc_name}"
    Purpose = "${var.cluster_name}"
    Kind = "POC"
  }
}

##################################### AWS CLUSTER AUTH #########################################

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
  depends_on = [ module.eks ]
}
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
  depends_on = [
    module.eks
  ]
}

locals {
  eks_cluster_name = var.cluster_name
}

##################################### AWS CLUSTER NODE POOL IAM ROLE BINDING #########################################

resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-node-group"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_iam_policy" "worker_policy" {
  name        = "${var.cluster_name}-worker-policy"
  description = "Worker policy for the ALB Ingress"
  policy = file("${path.module}/configs/worker-policy.json")
}

resource "aws_iam_role_policy_attachment" "ALBIngressEKSPolicyCustom" {
  policy_arn = aws_iam_policy.worker_policy.arn
  role       = aws_iam_role.node.name
}

##################################### AWS CLUSTER ENCRYPTION KEYS #########################################

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

##################################### AWS CLUSTER EKS SETUP #########################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"
  cluster_name    = local.eks_cluster_name
  cluster_version = "1.23"
  subnet_ids = module.ops-vpc.private_subnets
  vpc_id = module.ops-vpc.vpc_id
  cluster_encryption_config = [
    {
        provider_key_arn = "${aws_kms_key.eks.arn}"
        resources = ["secrets"]
    }
  ]
}

##################################### AWS CLUSTER PLUGINS #########################################

resource "aws_eks_addon" "csi-driver" {
  cluster_name = module.eks.cluster_name
  addon_name   = "aws-ebs-csi-driver"
  resolve_conflicts_on_update = "PRESERVE"
  depends_on = [ aws_eks_node_group.default-node-pool, 
                #  aws_eks_node_group.ha-node-pool 
               ]
}

resource "aws_eks_addon" "vpc-cni" {
  cluster_name = module.eks.cluster_name
  addon_name   = "vpc-cni"
  resolve_conflicts_on_update = "PRESERVE"
}

resource "aws_eks_addon" "coredns" {
  cluster_name = module.eks.cluster_name
  addon_name   = "coredns"
  resolve_conflicts_on_update = "PRESERVE"
  depends_on = [ aws_eks_node_group.default-node-pool ]
}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name = module.eks.cluster_name
  addon_name   = "kube-proxy"
  resolve_conflicts_on_update = "PRESERVE"
}


##################################### AWS CLUSTER NODE POOLS #########################################

resource "aws_eks_node_group" "default-node-pool" {
  cluster_name    = module.eks.cluster_name
  ami_type        = "AL2_x86_64"
  version         = "1.23"
  node_group_name = "${var.cluster_name}-default-node-pool"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = module.ops-vpc.private_subnets
  disk_size       = 200
  instance_types  = ["${var.cluster_node_type}"]
  scaling_config {
    desired_size = var.cluster_nodes
    max_size     = 10
    min_size     = 2
  }
  update_config {
    max_unavailable = 1
  }

  remote_access {
    ec2_ssh_key = var.aws_ssh_key
    source_security_group_ids = [module.ops-vpc.default_security_group_id]
  }
  depends_on = [ 
    aws_eks_addon.vpc-cni,
    aws_eks_addon.kube-proxy,
    # aws_eks_addon.coredns
  ]
}

##################################### AWS BASIC APPLICATIONS #########################################

resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  chart      = "cert-manager"
  repository = "https://charts.jetstack.io"
  namespace = "cert-manager"
  version    = "1.10.0"
  create_namespace = true
  cleanup_on_fail = true
  set {
    name = "installCRDs"
    value = "true"
  }
  depends_on = [ 
    aws_eks_node_group.default-node-pool
  ]
}

resource "helm_release" "ingress" {
  name       = "aws-load-balancer-controller"
  chart      = "${path.module}/dependencies/aws-load-balancer-controller"
  namespace = "kube-system"
  values = [file("${path.module}/dependencies/aws-load-balancer-controller/values.yaml")]
  set {
    name = "clusterName"
    value = module.eks.cluster_name
  }
  set {
    name = "region"
    value = data.aws_region.current.name
  }
  set {
    name = "vpcId"
    value = module.ops-vpc.vpc_id
  }
  depends_on = [ 
    aws_eks_node_group.default-node-pool
  ]
}


##################################### AWS CLUSTER AUTH CONFIG MAP #########################################

data "kubectl_file_documents" "aws-auth-cm" {
    content = templatefile("${path.module}/configs/aws-auth-cm.yaml", {
      node_pool_role_arn = "${aws_iam_role.node.arn}"
      }
    )
    # arn:aws:iam::829250931565:role/hsbc-ops-node-group
}


resource "kubectl_manifest" "aws-auth" {
  for_each  = data.kubectl_file_documents.aws-auth-cm.manifests
  yaml_body = each.value
  depends_on = [
    module.eks,
    aws_eks_node_group.default-node-pool
  ]
}

##################################### AWS GP3 STORAGE CLASS #########################################

data "kubectl_file_documents" "aws-ebs-gp3" {
    content = file("${path.module}/configs/ebs-gp3.yaml")
}

resource "kubectl_manifest" "aws-ebs" {
  for_each  = data.kubectl_file_documents.aws-ebs-gp3.manifests
  yaml_body = each.value
  depends_on = [
    module.eks,
    aws_eks_node_group.default-node-pool
  ]
}

##################################### CONFLUENT PLATFORM ON AWS EKS #########################################

data "kubectl_filename_list" "cfk-crds" {
    pattern = "${path.module}/dependencies/confluent-for-kubernetes/crds/*.yaml"
}

resource "kubectl_manifest" "cfk-crds" {
  count     = length(data.kubectl_filename_list.cfk-crds.matches)
  yaml_body = file(element(data.kubectl_filename_list.cfk-crds.matches, count.index))
  depends_on = [
    module.eks,
    aws_eks_node_group.default-node-pool
  ]
}

resource "helm_release" "confluent-operator" {
  name       = "confluent-operator"
  chart      = "${path.module}/dependencies/confluent-for-kubernetes"
  namespace = "confluent"
  cleanup_on_fail = true
  create_namespace = true
  values = [file("${path.module}/dependencies/confluent-for-kubernetes/values.yaml")]
  depends_on = [
    kubectl_manifest.cfk-crds
  ]
  # set {
  #   name = "license.secretRef"
  #   value = "cp-license"
  # }
}

data "kubectl_file_documents" "cfk-permissions" {
    content = file("${path.module}/dependencies/confluent-for-kubernetes/cfk-permission.yaml")
}

resource "kubectl_manifest" "cfk-permissions" {
  for_each  = data.kubectl_file_documents.cfk-permissions.manifests
  yaml_body = each.value
  depends_on = [
    helm_release.confluent-operator
  ]
}