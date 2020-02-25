resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }
}

resource "kubernetes_deployment" "vault" {
  metadata {
    name = "vault"
    labels = {
      app = "vault"
    }
    namespace = kubernetes_namespace.vault.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "vault"
      }
    }

    template {
      metadata {
        labels = {
          app = "vault"
        }
      }

      spec {
        container {
          name  = "vault"
          
          image = "vault"
          image_pull_policy = "Never"

          port {
            container_port = 8200
          }
          env {
            name = "VAULT_DEV_ROOT_TOKEN_ID"
            value = "test"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "vault" {
  metadata {
    name = "vault"
    labels = {
      app = kubernetes_deployment.vault.spec[0].template[0].metadata[0].labels.app
    }
    namespace = kubernetes_namespace.vault.metadata[0].name
  }
  spec {
    port {
      protocol = "TCP"
      port     = 8200
    }
    selector = {
      app = kubernetes_deployment.vault.spec[0].template[0].metadata[0].labels.app
    }
    type = "NodePort"
  }
}
