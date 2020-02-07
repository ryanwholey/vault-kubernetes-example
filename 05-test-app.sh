#!/usr/bin/env bash

: '
./05-test-app.sh \
  "http://$(minikube ip):$(kubectl get service vault -n vault -o jsonpath={.spec.ports[0].nodePort})" \
  "test-app" \
  "apps"
'

export VAULT_ADDR="$1"
APP_NAME="$2"
NAMESPACE="$3"
DB_HOSTNAME="${APP_NAME}-db.${NAMESPACE}.svc.cluster.local"

kubectl create namespace "$NAMESPACE"

vault policy write "${APP_NAME}-kv-ro" <(cat <<EOF
path "secret/data/${APP_NAME}/*" {
    capabilities = ["read", "list"]
}
EOF
)

vault write "auth/kubernetes/role/${APP_NAME}" \
  "bound_service_account_names=${APP_NAME}" \
  "bound_service_account_namespaces=${NAMESPACE}" \
  "policies=${APP_NAME}-kv-ro" \
  ttl=24h

vault kv put "secret/${APP_NAME}/config" \
  username="app" \
  password="secret" \
  ttl="30s"

cat <<EOF | kubectl apply -n ${NAMESPACE} -f -
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${APP_NAME}
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
        vault.hashicorp.com/agent-inject-status: "update"
        vault.hashicorp.com/role: "${APP_NAME}"
        vault.hashicorp.com/agent-inject-secret-foo: "secret/${APP_NAME}/config"
        vault.hashicorp.com/agent-inject-template-foo: |
          {{- with secret "secret/${APP_NAME}/config" -}}
          PG_CONNECTION_STRING=postgres://{{ .Data.data.username }}:{{ .Data.data.password }}@${DB_HOSTNAME}:5432/test_db
          {{- end -}}
      labels:
        app: ${APP_NAME} 
    spec:
      containers:
      - name: ${APP_NAME}
        image: test-app
        imagePullPolicy: Never
        ports:
          - name: http
            containerPort: 3000
        env:
        - name: PORT
          value: "3000"
        - name: ENV_FILE
          value: /vault/secrets/foo
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
      serviceAccountName: ${APP_NAME}
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: ${APP_NAME}
  name: ${APP_NAME}
spec:
  ports:
  - port: 3000
    protocol: TCP
    targetPort: 3000
  selector:
    app: ${APP_NAME}
  type: NodePort
EOF
