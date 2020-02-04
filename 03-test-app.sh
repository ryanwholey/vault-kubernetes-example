#!/usr/bin/env bash

: '
./03-test-app.sh \
  "http://$(minikube ip):$(kubectl get service vault -o jsonpath={.spec.ports[0].nodePort})" \
  "https://$(minikube ip):8443" \
  "test-app" \
  "default"
'

export VAULT_ADDR="$1"
KUBERNETES_API_URL="$2"
APP_NAME="$3"
NAMESPACE="$4"

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: vault-auth-${APP_NAME}
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: role-tokenreview-binding
  namespace: ${NAMESPACE}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: vault-auth-${APP_NAME}
  namespace: ${NAMESPACE}
---
EOF

VAULT_SA_NAME=$(kubectl get sa vault-auth-$APP_NAME -o jsonpath="{.secrets[*]['name']}")
SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)

vault write auth/kubernetes/config \
  token_reviewer_jwt="$SA_JWT_TOKEN" \
  kubernetes_host="$KUBERNETES_API_URL" \
  kubernetes_ca_cert="$SA_CA_CRT"

vault policy write "${APP_NAME}-kv-ro" <(cat <<EOF
path "secret/data/${APP_NAME}/*" {
    capabilities = ["read", "list"]
}
EOF
)

vault write "auth/kubernetes/role/${APP_NAME}" \
  bound_service_account_names=vault-auth-${APP_NAME} \
  bound_service_account_namespaces=default \
  policies=${APP_NAME}-kv-ro \
  ttl=24h

vault kv put secret/${APP_NAME}/config \
  foo='bar' \
  baz='fleep' \
  ttl='30s'

cat <<EOF | kubectl apply -n ${NAMESPACE} -f -
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${APP_NAME}
  labels:
    app: ${APP_NAME}
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ${APP_NAME}
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/agent-inject-secret-foo: secret/${APP_NAME}/config
        vault.hashicorp.com/agent-inject-secret-bar: secret/${APP_NAME}/config
        vault.hashicorp.com/role: "${APP_NAME}"
      labels:
        app: ${APP_NAME} 
    spec:
      containers:
      - name: ${APP_NAME}
        image: alpine:3.7
        args:
          - tail
          - -f
          - /dev/null
      serviceAccountName: vault-auth-${APP_NAME}
EOF
