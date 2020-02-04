#!/usr/bin/env bash

: '
./01-vault-server.sh
'

cat <<EOF | kubectl apply -f -
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vault
spec:
  selector:
    matchLabels:
      run: vault
  replicas: 1
  template:
    metadata:
      labels:
        run: vault
    spec:
      containers:
      - name: vault
        image: vault
        ports:
        - containerPort: 8200
        env:
        - name: VAULT_DEV_ROOT_TOKEN_ID
          value: "test"
---
apiVersion: v1
kind: Service
metadata:
  name: vault
  labels:
    run: vault
spec:
  ports:
  - port: 8200
    protocol: TCP
  selector:
    run: vault
  type: "NodePort"
EOF

until nc -z $(minikube ip) $(kubectl get service vault -o jsonpath={.spec.ports[0].nodePort}) ; do echo 'setting up Vault..' && sleep 3 ; done
export VAULT_ADDR="http://$(minikube ip):$(kubectl get service vault -o jsonpath={.spec.ports[0].nodePort})"

vault auth enable kubernetes
