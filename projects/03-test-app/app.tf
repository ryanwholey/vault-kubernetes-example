data "vault_policy_document" "app" {
  rule {
    path         = "${vault_mount.postgres.path}/creds/${local.app_name}"
    capabilities = ["read"]
  }
  rule {
    path         = "auth/token/renew-self"
    capabilities = ["update"]
  }
  rule {
    path         = "auth/token/revoke-self"
    capabilities = ["update"]
  }
}

resource vault_policy app {
  name   = "${local.app_name}-ro"
  policy = data.vault_policy_document.app.hcl
}

data vault_kubernetes_auth_backend_config kubernetes {}

resource vault_kubernetes_auth_backend_role app {
  backend                          = data.vault_kubernetes_auth_backend_config.kubernetes.backend
  role_name                        = local.app_name
  bound_service_account_names      = [kubernetes_service_account.app.metadata[0].name]
  bound_service_account_namespaces = [kubernetes_namespace.apps.metadata[0].name]
  token_policies                   = [vault_policy.app.name]
  token_ttl                        = 0 // seconds
}

resource vault_database_secret_backend_role app {
  backend             = vault_mount.postgres.path
  name                = local.app_name
  db_name             = vault_database_secret_backend_connection.postgres.name

  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';"
  ]

  default_ttl = 60 * 2 // seconds
  max_ttl     = 60 * 5 // seconds
}

resource kubernetes_service_account app {
  metadata {
    name      = local.app_name
    namespace = kubernetes_namespace.apps.metadata[0].name
  }
  automount_service_account_token = true
}

resource kubernetes_deployment app {
  metadata {
    name = local.app_name
    labels = {
      app = local.app_name
    }
    namespace = kubernetes_namespace.apps.metadata[0].name
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = local.app_name
      }
    }

    template {
      metadata {
        labels = {
          app = local.app_name
        }
        annotations = {
          "vault.hashicorp.com/agent-inject"             = "true"
          "vault.hashicorp.com/agent-inject-status"      = "update"
          "vault.hashicorp.com/role"                     = vault_database_secret_backend_role.app.name
          "vault.hashicorp.com/agent-inject-secret-db"   = "${vault_mount.postgres.path}/creds/${local.app_name}"
          "vault.hashicorp.com/agent-inject-template-db" = <<EOF
            {{- with secret "${vault_mount.postgres.path}/creds/${local.app_name}" -}}
            PG_CONNECTION_STRING=postgres://{{ .Data.username }}:{{ .Data.password }}@${kubernetes_service.postgres.spec[0].cluster_ip}:${kubernetes_service.postgres.spec[0].port[0].port}/${local.app_name}-db
            {{- end }}
            EOF
        }
      }

      spec {
        service_account_name            = kubernetes_service_account.app.metadata[0].name
        automount_service_account_token = true

        container {
          name  = local.app_name
          image = local.app_name

          image_pull_policy = "Never"

          port {
            container_port = 3000
          }
          env {
            name  = "PORT"
            value = 3000
          }
          env {
            name  = "ENV_FILE"
            value = "/vault/secrets/db"
          }
          env {
            name = "POD_NAME"
            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app" {
  metadata {
    name = local.app_name
    labels = {
      app = kubernetes_deployment.app.spec[0].template[0].metadata[0].labels.app
    }
    namespace = kubernetes_namespace.apps.metadata[0].name
  }
  spec {
    port {
      protocol    = "TCP"
      port        = 3000
      target_port = 3000
    }
    selector = {
      app = kubernetes_deployment.app.spec[0].template[0].metadata[0].labels.app
    }
    type = "NodePort"
  }
}
