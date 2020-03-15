set -x
source ./utils.sh

echo "Deleting app if it exists"
kubectl delete -f https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/aspnetapp.yaml

echo "Install the app again"
kubectl apply -f https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/aspnetapp.yaml

output=$(GetIngressIPWithRetry "ingress/aspnetapp")
echo "Found ingress Ip: $output"

if [[ $output != FailStatus ]]
then
    echo "Curling $output and waiting until 200 is returned. If we fail after trying multiple times, then test should fail"
    output=$(WaitUntil200 $ip)
fi

echo "Deleting the app"
kubectl delete -f https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/aspnetapp.yaml


echo "Test status: $output"
if [[ $output == FailStatus ]]
then
    exit -1
fi
exit 0