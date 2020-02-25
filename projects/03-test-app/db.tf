resource "kubernetes_deployment" "postgres" {
  metadata {
    name = "${local.app_name}-db"
    labels = {
      app = "${local.app_name}-db"
    }
    namespace = kubernetes_namespace.apps.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "${local.app_name}-db"
      }
    }

    template {
      metadata {
        labels = {
          app = "${local.app_name}-db"
        }
      }

      spec {
        container {
          image = "postgres:12.1"
          name  = "${local.app_name}-db"
          port {
            container_port = 5432
          }
          env {
            name = "POSTGRES_USER"
            value = local.pg_username
          }
          env {
            name = "POSTGRES_PASSWORD"
            value = local.pg_password
          }          
          env {
            name = "POSTGRES_DB"
            value = "${local.app_name}-db"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "postgres" {
  metadata {
    name = "${local.app_name}-db"
    labels = {
      app = kubernetes_deployment.postgres.spec[0].template[0].metadata[0].labels.app
    }
    namespace = kubernetes_namespace.apps.metadata[0].name
  }
  spec {
    port {
      protocol    = "TCP"
      port        = 5432
      target_port = 5432
    }
    selector = {
      app = kubernetes_deployment.postgres.spec[0].template[0].metadata[0].labels.app
    }
    type = "NodePort"
  }
}

// This should live in the vault setup project
resource "vault_mount" "postgres" {
  path = "database"
  type = "database"
}

resource "vault_database_secret_backend_connection" "postgres" {
  name          = "${local.app_name}-db"
  backend       = vault_mount.postgres.path
  allowed_roles = ["*"]

  postgresql {
    connection_url = format("postgres://%s:%s@%s:%s/%s?sslmode=disable", 
      local.pg_username,
      local.pg_password,
      var.minikube_ip,
      kubernetes_service.postgres.spec[0].port[0].node_port,
      "${local.app_name}-db"
    )
  }

  depends_on = [vault_mount.postgres]
}

