#!/usr/bin/env bash

: '
./04-test-app-db-vault.sh \
  "http://$(minikube ip):$(kubectl get service vault -n vault -o jsonpath={.spec.ports[0].nodePort})" \
  "test-app" \
  "apps"
'

export VAULT_ADDR="$1"
APP_NAME="$2"
DB_NAME="${2}-db"
APP_NAMESPACE="${3}"

POSTGRES_USER="app"
POSTGRES_PASSWORD="secret"
POSTGRES_DB="test_db"
POSTGRES_HOST=$(minikube ip)
POSTGRES_PORT=$(kubectl get service ${DB_NAME} -n ${APP_NAMESPACE} -o jsonpath={.spec.ports[0].nodePort})

vault secrets enable database

vault write "database/config/${DB_NAME}" \
  plugin_name=postgresql-database-plugin \
  allowed_roles="*" \
  connection_url="postgresql://{{username}}:{{password}}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}?sslmode=disable" \
  username="$POSTGRES_USER" \
  password="$POSTGRES_PASSWORD"
