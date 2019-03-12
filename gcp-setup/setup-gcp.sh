#!/bin/bash
#tag::ubuntu[]
apt-get install google-cloud-sdk
#end::ubuntu[]
apt-get remove google-cloud-sdk
#tag::general[]
curl https://sdk.cloud.google.com | bash
#end::general[]
#tag::enable_container_apis[]
gcloud services enable container.googleapis.com
#end::enable_container_apis[]
PROJECT_ID="boos-demo-projects-are-rad"
#tag::configure_cloud_sdk[]
gcloud auth login # Launches a web browser to login with
gcloud config set project "$PROJECT_ID" #Project ID is your Google project ID
#end::configure_cloud_sdk[]
ZONE="us-central1-a" # For TPU access
CLUSTER_NAME="ci-cluster"
#tag::launch_cluster[]
gcloud beta container clusters create $CLUSTER_NAME \
       --zone $ZONE \
       --machine-type "n1-standard-8" \
       --disk-type "pd-standard" \
       --disk-size "100" \
       --scopes "https://www.googleapis.com/auth/cloud-platform" \
       --addons HorizontalPodAutoscaling,HttpLoadBalancing \
       --enable-autoupgrade \
       --enable-autorepair \
       --enable-autoscaling --min-nodes 1 --max-nodes 10 --num-nodes 2
#end::launch_cluster[]
#tag::connect_to_cluster[]
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE
#end::connect_to_cluster[]
#tag::delete_cluster[]
gcloud beta container clusters delete $CLUSTER_NAME --zone $ZONE
#end::delete_cluster[]
#tag::kfctl_platform[]
export CLIENT_SECRET=OAUTH_SECRET
export CLIENT_ID=OAUTH_CLIENT_ID
KFAPP=Kubeflow_Application_Name # Also used for the cluster & deployment name
kfctl.sh init ${KFAPP} --platform gcp --project ${GCP_PROJECT}
pushd ${KFAPP}
kfctl.sh generate platform
kfctl.sh apply platform
#end::kfcl_platform[]
#end::kfctl_k8s[]
kfctl.sh generate k8s
kfctl.sh apply k8s
#end::kfctl_k8s[]
