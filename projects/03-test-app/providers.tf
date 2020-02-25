provider kubernetes {}

provider vault {
  address = "http://${var.minikube_ip}:${data.kubernetes_service.vault.spec[0].port[0].node_port}"
}
