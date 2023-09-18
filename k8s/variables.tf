variable "cluster_name" {type = string}
variable "cluster_region" {type = string}
variable "cluster_nodes" {
  type = number
  default=2
}
variable "cluster_node_type" {
  type = string
  default = "m6i.large"
}
variable "vpc_cidr" {
  type = string
  default = "172.20.0.0/22"
}
variable "vpc_name" {
  type = string
}
variable "aws_api_key" {
  type = string
}
variable "aws_api_secret" {
  type = string
}
variable "aws_ssh_key" {
  type = string
}
variable "confluent_k8s_namespace" {
  type = string
}
variable "mrc_vpc_cidrs" {
  type = list(string)
}