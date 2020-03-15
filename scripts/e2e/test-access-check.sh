set -x
source ./utils.sh

subscription=$1
aksClusterGroupName=$2
aksClusterName=$3
applicationGatewayName=$4
identityPrincipalId=$5
nodeResourceGroupName=$(az aks show -n $aksClusterName -g $aksClusterGroupName --subscription $subscription --query "nodeResourceGroup" -o tsv)

echo "Deleting app if it exists"
kubectl delete -f https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/aspnetapp.yaml

output=$(az role assignment list --assignee $identityPrincipalId --subscription $subscription --all -o json | jq -r ".[].id") | xargs 
echo "Found existing role assignment: $output"
if [[ $output != "" ]]
then
    echo "Deleting old role assigment for AGIC identity"
    echo $output | xargs az role assignment delete --ids
fi

echo "Deleting AGIC pod if present, this will create a new pod"
DeleteAGICPod

sleep 30

echo "Creating reader role assignment for AGIC"
az role assignment create --role Reader -g "$nodeResourceGroupName" --assignee $identityPrincipalId --subscription $subscription

sleep 30

echo "Creating contributor role assignment for AGIC"
az role assignment create --role Contributor \
--scope "/subscriptions/$subscription/resourceGroups/$nodeResourceGroupName/providers/Microsoft.Network/applicationGateways/$applicationGatewayName" \
--assignee $identityPrincipalId \
--subscription $subscription

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