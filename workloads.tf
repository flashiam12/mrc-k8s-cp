#################################### CREATE NAMESPACE FOR CONFLUENT #######################
resource "kubernetes_namespace" "mrc-east" {
  provider = kubernetes.east-cluster-kubernetes-raw
  metadata {
    annotations = {
      purpose = "poc-east"
    }
    labels = {
      cluster = "citi-mrc-poc-east"
    }
    name = "east"
  }
}
resource "kubernetes_namespace" "mrc-central" {
  provider = kubernetes.central-cluster-kubernetes-raw
  metadata {
    annotations = {
      name = "poc-central"
    }
    labels = {
      cluster = "citi-mrc-poc-central"
    }
    name = "central"
  }
}
resource "kubernetes_namespace" "mrc-west" {
  provider = kubernetes.west-cluster-kubernetes-raw
  metadata {
    annotations = {
      name = "poc-west"
    }
    labels = {
      cluster = "citi-mrc-poc-west"
    }
    name = "west"
  }
}
#################################### CREATE KUBE DNS SERVICE AS LB #######################
data "kubectl_file_documents" "dns-lb-east" {
    content = file("${path.module}/multi-region-clusters/internal-listeners/networking/eks/dns-lb.yaml")
}
resource "kubectl_manifest" "dns-lb-east" {
  provider = kubectl.east-cluster-kubectl
  for_each  = data.kubectl_file_documents.dns-lb-east.manifests
  yaml_body = each.value
  depends_on = [
    module.k8s-east
  ]
}

data "kubectl_file_documents" "dns-lb-west" {
    content = file("${path.module}/multi-region-clusters/internal-listeners/networking/eks/dns-lb.yaml")
}
resource "kubectl_manifest" "dns-lb-west" {
  provider = kubectl.west-cluster-kubectl
  for_each  = data.kubectl_file_documents.dns-lb-west.manifests
  yaml_body = each.value
  depends_on = [
    module.k8s-west
  ]
}

data "kubectl_file_documents" "dns-lb-central" {
    content = file("${path.module}/multi-region-clusters/internal-listeners/networking/eks/dns-lb.yaml")
}
resource "kubectl_manifest" "dns-lb-central" {
  provider = kubectl.central-cluster-kubectl
  for_each  = data.kubectl_file_documents.dns-lb-central.manifests
  yaml_body = each.value
  depends_on = [
    module.k8s-central
  ]
}
################################# K8S KUBE DNS LB SERVICE ######################################

data "kubernetes_service" "kube-dns-lb-east" {
  provider = kubernetes.east-cluster-kubernetes-raw
  metadata {
    name = "kube-dns-lb"
    namespace = "kube-system"
  }
}

data "dns_a_record_set" "kube-dns-lb-east" {
  host = data.kubernetes_service.kube-dns-lb-east.status.0.load_balancer.0.ingress.0.hostname
}

data "kubernetes_service" "kube-dns-lb-west" {
  provider = kubernetes.west-cluster-kubernetes-raw
  metadata {
    name = "kube-dns-lb"
    namespace = "kube-system"
  }
}

data "dns_a_record_set" "kube-dns-lb-west" {
  host = data.kubernetes_service.kube-dns-lb-west.status.0.load_balancer.0.ingress.0.hostname
}

data "kubernetes_service" "kube-dns-lb-central" {
  provider = kubernetes.central-cluster-kubernetes-raw
  metadata {
    name = "kube-dns-lb"
    namespace = "kube-system"
  }
}

data "dns_a_record_set" "kube-dns-lb-central" {
  host = data.kubernetes_service.kube-dns-lb-central.status.0.load_balancer.0.ingress.0.hostname
}

################################# UPDATE COREDNS CONFIG FOR INTER CLUSTER CROSS REGION DNS RESOLUTION ####################

resource "kubernetes_config_map_v1" "corefile-central" {
  provider = kubernetes.central-cluster-kubernetes-raw
  metadata {
    name = "coredns"
    namespace = "kube-system"
  }

  data = {
    "Corefile" = templatefile("${path.module}/dnscorefiles/central.Corefile", {
        east_coredns_lb_ip = data.dns_a_record_set.kube-dns-lb-east.addrs.0,
        west_coredns_lb_ip = data.dns_a_record_set.kube-dns-lb-west.addrs.0
    })
  }
}

resource "kubernetes_config_map_v1" "corefile-east" {
  provider = kubernetes.east-cluster-kubernetes-raw
  metadata {
    name = "coredns"
    namespace = "kube-system"
    labels = {
      "eks.amazonaws.com/component" = "coredns"
      "k8s-app" = "kube-dns"
    }
  }

  data = {
    "Corefile" = templatefile("${path.module}/dnscorefiles/east.Corefile", {
        central_coredns_lb_ip = data.dns_a_record_set.kube-dns-lb-central.addrs.0,
        west_coredns_lb_ip = data.dns_a_record_set.kube-dns-lb-west.addrs.0
    })
  }
}

resource "kubernetes_config_map_v1" "corefile-west" {
  provider = kubernetes.west-cluster-kubernetes-raw
  metadata {
    name = "coredns"
    namespace = "kube-system"
  }

  data = {
    "Corefile" = templatefile("${path.module}/dnscorefiles/west.Corefile", {
        central_coredns_lb_ip = data.dns_a_record_set.kube-dns-lb-central.addrs.0,
        east_coredns_lb_ip = data.dns_a_record_set.kube-dns-lb-east.addrs.0
    })
  }
}





