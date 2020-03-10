set -x
source ./utils.sh

# delete app
kubectl delete -f https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/aspnetapp.yaml

# install app
kubectl apply -f https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/aspnetapp.yaml

# Get ip for the ingress
ip=$(GetIngressIPWithRetry "ingress/aspnetapp")

# wait until we get 200
WaitUntil200 $ip

# delete app
kubectl delete -f https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/aspnetapp.yaml