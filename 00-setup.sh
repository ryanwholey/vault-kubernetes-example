: '
./00-setup.sh
'

minikube start
eval $(minikube docker-env)
cd test-app
docker build . -t test-app

