#!/usr/bin/env bash

# Create an azure cluster

AZURE_CLUSTER_NAME=${AZURE_CLUSTER_NAME:="azure-kf-test"}
echo "Starting up Azure K8s cluster"
az configure --defaults location=westus
# Get the subscription id
SUBSCRIPTION_ID=$(az account show | jq -r ".id")
az ad sp create-for-rbac --name ServicePrincipalName | tee -a principal_results
AZ_CLIENT_ID=$(cat principal_results | jq -r ".appId")
AZ_CLIENT_SECRET=$(cat principal_results | jq -r ".password")
AZ_TENANT_ID=$(cat principal_results | jq -r ".tenant")

kfctl.sh init ${AZURE_CLUSTER_NAME} --platform azure -V --azClientId ${AZ_CLIENT_ID} --azClientSecret ${AZ_CLIENT_SECRET} --azTenantId ${AZ_TENANT_ID} --azSubscriptionId ${SUBSCRIPTION_ID} --azLocation westus --azNodeSize 5
pushd $AZURE_CLUSTER_NAME
source env.sh
kfctl.sh generate all
kfctl.sh apply all
az group exists -n kf-westus || az group create -n kf-westus
