locals {
  vault_helm_version = "0.4.0"
}

# resource "null_resource" "vault_helm" {
#   provisioner "local-exec" {
#     working_dir = "/tmp"

#     command = <<EOT
#     curl -fsSL -o ./vault-helm-${local.vault_helm_version}.tgz https://github.com/hashicorp/vault-helm/archive/v${local.vault_helm_version}.tar.gz && \
#     tar xzf ./vault-helm-${local.vault_helm_version}.tgz
#     EOT
#   }
# }

data kubernetes_service vault {
  metadata {
    name      = "vault"
    namespace = "vault"
  }
}

data kubernetes_service kubernetes {
  metadata {
    name = "kubernetes"
  }
}

resource helm_release vault_injector_helm {
  name       = "vault-sidecar"
  chart      = "/tmp/vault-helm-${local.vault_helm_version}"
  namespace  = "vault"

  values = [
    jsonencode({
      server = {
        service = {
          enabled = false
        }
        dataStorage = {
          enabled = false
        }
        standalone = {
          enabled =  false
        }
      }
      injector = {
        externalVaultAddr = "http://${data.kubernetes_service.vault.spec[0].cluster_ip}:${data.kubernetes_service.vault.spec[0].port[0].port}"
      }
    })
  ]

  depends_on = [
    # null_resource.vault_helm
  ]
}

resource kubernetes_service_account vault_auth {
  metadata {
    name      = "vault-auth"
    namespace = "vault"
  }
  automount_service_account_token = true
}

resource kubernetes_cluster_role_binding vault_auth {
  metadata {
    name = "role-tokenreview-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "vault-auth"
    namespace = "vault"
  }
}

data kubernetes_secret vault_auth {
  metadata {
    name      = kubernetes_service_account.vault_auth.default_secret_name
    namespace = kubernetes_service_account.vault_auth.metadata.0.namespace
  }
}

resource vault_auth_backend kubernetes {
  type = "kubernetes"
}

resource vault_kubernetes_auth_backend_config kubernetes {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = "https://${var.minikube_ip}:8443"
  kubernetes_ca_cert = data.kubernetes_secret.vault_auth.data["ca.crt"]
  token_reviewer_jwt = data.kubernetes_secret.vault_auth.data.token
}

output ca-cert {
  value = data.kubernetes_secret.vault_auth.data["ca.crt"]
}

output jwt {
  value = data.kubernetes_secret.vault_auth.data.token  
}

output kubernetes_host {
  # value = "https://${var.minikube_ip}:${data.kubernetes_service.kubernetes.spec[0].port[0].node_port}"
  value = data.kubernetes_service.kubernetes.spec[0].port
}

