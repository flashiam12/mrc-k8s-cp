output "vpc_id" {
  value = module.ops-vpc.vpc_id
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