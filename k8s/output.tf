output "vpc_id" {
  value = module.ops-vpc.vpc_id
}
output "default_security_group_id" {
  value = module.ops-vpc.default_security_group_id
}
output "public_subnet_cidr" {
  value = module.ops-vpc.public_subnets
}
output "cluster_endpoint" {
  value = data.aws_eks_cluster.cluster.endpoint
}
output "cluster_ca_cert" {
  value = data.aws_eks_cluster.cluster.certificate_authority.0.data
}
output "cluster_auth_token" {
  value = data.aws_eks_cluster_auth.cluster.token
}
