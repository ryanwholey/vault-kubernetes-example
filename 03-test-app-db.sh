#!/usr/bin/env bash

: '
./03-test-app-db.sh \
  "test-app" \
  "apps"
'

DB_NAME="${1}-db"
NAMESPACE="$2"

kubectl create namespace "$NAMESPACE"

cat <<EOF | kubectl apply -n ${NAMESPACE} -f -
---
kind: Service
apiVersion: v1
metadata:
  name: ${DB_NAME}
spec:
  ports:
    - protocol: TCP
      port: 5432
      targetPort: 5432
  selector:
    app: ${DB_NAME}
  type: NodePort
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${DB_NAME}
  labels:
    app: ${DB_NAME}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${DB_NAME}
  template:
    metadata:
      labels:
        app: ${DB_NAME} 
    spec:
      containers:
      - name: ${DB_NAME}
        image: postgres:12.1
        env:
        - name: POSTGRES_USER
          value: app
        - name: POSTGRES_PASSWORD
          value: secret
        - name: POSTGRES_DB
          value: test_db
EOF

