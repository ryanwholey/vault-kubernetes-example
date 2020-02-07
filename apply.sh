#!/usr/bin/env bash

VAULT_SERVER_NAMESPACE="vault"
APP_NAMESPACE="apps"
APP_NAME="test-app"

./00-setup.sh

MINIKUBE_IP=$(minikube ip)
KUBERNETES_API_ADDR="https://${MINIKUBE_IP}:8443"

./01-vault-server.sh \
  "$VAULT_SERVER_NAMESPACE" \
  "http://${MINIKUBE_IP}:8443"

VAULT_ADDR="http://${MINIKUBE_IP}:$(kubectl get service vault -n ${VAULT_SERVER_NAMESPACE} -o jsonpath={.spec.ports[0].nodePort})"

./02-vault-kubernetes.sh \
  "$VAULT_ADDR" \
  "$KUBERNETES_API_ADDR"

./03-test-app-db.sh \
  "$APP_NAME" \
  "$APP_NAMESPACE"

sleep 10

./05-test-app.sh \
  "$VAULT_ADDR" \
  "$APP_NAME" \
  "$APP_NAMESPACE"

APP_PORT=$(kubectl get service ${APP_NAME} -n ${APP_NAMESPACE} -o jsonpath={.spec.ports[0].nodePort})
APP_URL="http://${MINIKUBE_IP}:${APP_PORT}"
until nc -z "$MINIKUBE_IP" "$APP_PORT" ; do echo "Setting up app.." && sleep 3 ; done
echo curl "$APP_URL/credentials | jq"