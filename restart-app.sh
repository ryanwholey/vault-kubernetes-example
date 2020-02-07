#!/bin/bash

cd test-app
docker build . -t test-app
cd ../

kubectl delete deployment test-app -n apps || true
kubectl delete svc test-app -n apps || true

./05-test-app.sh \
  "http://$(minikube ip):$(kubectl get service vault -n vault-external -o jsonpath={.spec.ports[0].nodePort})" \
  "test-app" \
  "apps"

