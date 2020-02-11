#!/usr/bin/env bash

TEST_APP_URL="http://$(minikube ip):$(kubectl get service test-app -n apps -o jsonpath={.spec.ports[0].nodePort})"

while true ;
do
    curl -fsS "${TEST_APP_URL}/credentials" | jq
    sleep 1
done

