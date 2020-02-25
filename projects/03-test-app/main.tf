locals {
  app_name    = "test-app"
  pg_username = "admin"
  pg_password = "password"
}

data "kubernetes_service" "vault" {
  metadata {
    name      = "vault"
    namespace = "vault"
  }
}

resource "kubernetes_namespace" "apps" {
  metadata {
    name = "apps"
  }
}
