#!/usr/bin/env bash

: '
./04-test-app-db-vault.sh \
  "http://$(minikube ip):$(kubectl get service vault -n vault -o jsonpath={.spec.ports[0].nodePort})" \
  "test-app"
'

