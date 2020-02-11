#!/usr/bin/env bash

: '
./05-test-app.sh \
  "http://$(minikube ip):$(kubectl get service vault -n vault -o jsonpath={.spec.ports[0].nodePort})" \
  "test-app" \
  "apps"
'

export VAULT_ADDR="$1"
APP_NAME="$2"
DB_NAME="${2}-db"
NAMESPACE="$3"
DB_HOSTNAME="${APP_NAME}-db.${NAMESPACE}.svc.cluster.local"
POSTGRES_DB="test_db"

kubectl create namespace "$NAMESPACE"

vault policy write "${APP_NAME}-ro" <(cat <<EOF
path "database/creds/${APP_NAME}" {
  capabilities = ["read"]
}
path "sys/leases/renew" {
  capabilities = ["create"]
}
path "sys/leases/revoke" {
  capabilities = ["update"]
}
EOF
)

vault write "auth/kubernetes/role/${APP_NAME}" \
  "bound_service_account_names=${APP_NAME}" \
  "bound_service_account_namespaces=${NAMESPACE}" \
  "policies=${APP_NAME}-ro" \
  ttl="0"

vault write "database/roles/${APP_NAME}" \
  db_name=${DB_NAME} \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
  default_ttl="5m" \
  max_ttl="10m"

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
        vault.hashicorp.com/agent-inject-secret-db: 'database/roles/${APP_NAME}'
        vault.hashicorp.com/agent-inject-template-db: |
          {{- with secret "database/creds/${APP_NAME}" -}}
          PG_CONNECTION_STRING=postgres://{{ .Data.username }}:{{ .Data.password }}@${DB_HOSTNAME}:5432/${POSTGRES_DB}
          {{- end }}
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
          value: /vault/secrets/db
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        livenessProbe:
          failureThreshold: 3
          httpGet:
            path: /system/health/alive
            port: 3000
            scheme: HTTP
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 1
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /system/health/ready
            port: 3000
            scheme: HTTP
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 1
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
