output namespace {
  value = kubernetes_namespace.vault
}

output deployment {
  value = kubernetes_deployment.vault
}

output service {
  value = kubernetes_service.vault
}