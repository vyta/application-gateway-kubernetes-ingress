set -x
source ./utils.sh

subscription=$1
aksClusterGroupName=$2
aksClusterName=$3
applicationGatewayName=$4
identityPrincipalId=$5
nodeResourceGroupName=$(az aks show -n $aksClusterName -g $aksClusterGroupName --subscription $subscription --query "nodeResourceGroup" -o tsv)

# delete app
kubectl delete -f https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/aspnetapp.yaml

# delete role assignment
az role assignment list --assignee $identityPrincipalId --subscription $subscription --all -o json | jq -r ".[].id" | xargs az role assignment delete --ids

# delete the app gw pod
DeleteAGICPod

# sleep for 30 seconds
sleep 30

# add role assignment for resource group
az role assignment create --role Reader -g "$nodeResourceGroupName" --assignee $identityPrincipalId --subscription $subscription

sleep 10

# add role assignment for app gateway
az role assignment create --role Contributor \
--scope "/subscription/$subscription/resourceGroups/$nodeResourceGroupName/applicationGateways/$applicationGatewayName" \
--assignee $identityPrincipalId \
--subscription $subscription

# install app
kubectl apply -f https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/aspnetapp.yaml

# Wait to get an IP for the ingress
ip=$(GetIngressIPWithRetry "ingress/aspnetapp")

# wait until we get 200
WaitUntil200 $ip

# delete app
kubectl delete -f https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/aspnetapp.yaml