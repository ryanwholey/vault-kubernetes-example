#!/usr/bin/env bash

: '
./delete-vault-state.sh \
  "http://$(minikube ip):$(kubectl get service vault -n vault -o jsonpath={.spec.ports[0].nodePort})" \
  "test-app" \
'

kubectl delete namespace apps
kubectl delete namespace vault
