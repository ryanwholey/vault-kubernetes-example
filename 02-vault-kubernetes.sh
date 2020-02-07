#!/usr/bin/env bash

: '
./02-vault-kubernetes.sh \
  "http://$(minikube ip):$(kubectl get service vault -n vault -o jsonpath={.spec.ports[0].nodePort})" \
  "https://$(minikube ip):8443"
'

VERSION=0.2.0
export VAULT_ADDR="$1"
KUBERNETES_API_URL="$2"

curl -fsSL -o "/tmp/vault-k8s-${VERSION}.tgz" https://github.com/hashicorp/vault-k8s/archive/v${VERSION}.tar.gz
tar xzf "/tmp/vault-k8s-${VERSION}.tgz" -C /tmp

sed -i".bak" "s|https://vault.\$(NAMESPACE).svc:8200|${VAULT_ADDR}|g" "/tmp/vault-k8s-${VERSION}/deploy/injector-deployment.yaml"

kubectl create namespace vault
kubectl apply -f "/tmp/vault-k8s-${VERSION}/deploy/injector-rbac.yaml" --namespace=vault
kubectl apply -f "/tmp/vault-k8s-${VERSION}/deploy/injector-service.yaml" --namespace=vault
kubectl apply -f "/tmp/vault-k8s-${VERSION}/deploy/injector-deployment.yaml" --namespace=vault
kubectl apply -f "/tmp/vault-k8s-${VERSION}/deploy/injector-mutating-webhook.yaml" --namespace=vault

kubectl create namespace vault

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: vault-auth
  namespace: vault
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: role-tokenreview-binding
  namespace: vault
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
  - kind: ServiceAccount
    name: vault-auth
    namespace: vault
EOF

VAULT_SA_NAME=$(kubectl get sa vault-auth -n vault -o jsonpath="{.secrets[*]['name']}")
SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -n vault -o jsonpath="{.data.token}" | base64 --decode; echo)
SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -n vault -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)

vault write auth/kubernetes/config \
  token_reviewer_jwt="$SA_JWT_TOKEN" \
  kubernetes_host="$KUBERNETES_API_URL" \
  kubernetes_ca_cert="$SA_CA_CRT"
