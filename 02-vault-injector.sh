#!/usr/bin/env bash

: '
./02-vault-injector.sh \
  "http://$(minikube ip):$(kubectl get service vault -o jsonpath={.spec.ports[0].nodePort})"
'

VERSION=0.2.0
VAULT_ADDR="$1"

curl -fsSL -o "/tmp/vault-k8s-${VERSION}.tgz" https://github.com/hashicorp/vault-k8s/archive/v${VERSION}.tar.gz
tar xzf "/tmp/vault-k8s-${VERSION}.tgz" -C /tmp

sed -i".bak" "s|https://vault.\$(NAMESPACE).svc:8200|${VAULT_ADDR}|g" "/tmp/vault-k8s-${VERSION}/deploy/injector-deployment.yaml"

kubectl create namespace vault
kubectl apply -f "/tmp/vault-k8s-${VERSION}/deploy/injector-rbac.yaml" --namespace=vault
kubectl apply -f "/tmp/vault-k8s-${VERSION}/deploy/injector-service.yaml" --namespace=vault
kubectl apply -f "/tmp/vault-k8s-${VERSION}/deploy/injector-deployment.yaml" --namespace=vault
kubectl apply -f "/tmp/vault-k8s-${VERSION}/deploy/injector-mutating-webhook.yaml" --namespace=vault
