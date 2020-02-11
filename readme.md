# Kubernetes Vault Integration

Uses the vault agent sidecar system to inject secrets into a shared volume for an application container to pick up and use. 

## Steps
./00-setup.sh
./01-vault-server.sh \
  "vault" \
  "http://$(minikube ip):8443"
./02-vault-kubernetes.sh \
  "http://$(minikube ip):$(kubectl get service vault -n vault -o jsonpath={.spec.ports[0].nodePort})" \
  "https://$(minikube ip):8443"
./03-test-app-db.sh \
  "test-app" \
  "apps"
./04-test-app-db-vault.sh \
  "http://$(minikube ip):$(kubectl get service vault -n vault -o jsonpath={.spec.ports[0].nodePort})" \
  "test-app" \
  "apps"
./05-test-app.sh \
  "http://$(minikube ip):$(kubectl get service vault -n vault -o jsonpath={.spec.ports[0].nodePort})" \
  "test-app" \
  "apps"
