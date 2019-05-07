#!/bin/bash


set -ex
# Hi friends! I'm the solution guide. If you get stuck I'm here to help
# Some other places you might want to look for help first:
# 1) 

# Optionally, toss a hand grenade in your current GCP setup with:
# ./cleanup.sh
# rm -rf $HOME
# surf to https://console.cloud.google.com/kubernetes/list
# and delete all the clusters.


echo "Download and run 'fast-start.sh'"
wget https://raw.githubusercontent.com/intro-to-ml-with-kubeflow/intro-to-ml-with-kubeflow-examples/master/multi-cloud/fast-start.sh
chmod +x fast-start.sh
./fast-start.sh
# shellcheck disable=SC1090
source ~/.bashrc
echo "OK... That seemed to go well."

echo "Setting up kubeflow project"
export G_KF_APP=${G_KF_APP:="g-kf-app"}
kfctl init ${G_KF_APP} --platform gcp --project ${GOOGLE_PROJECT} --use_basic_auth -V

pushd $G_KF_APP
kfctl generate all -V --zone $GZONE
kfctl apply all -V # Sometimes fails re-run if so

# Add extra permissions
export SERVICE_ACCOUNT=user-gcp-sa
export SERVICE_ACCOUNT_EMAIL=${SERVICE_ACCOUNT}@${GOOGLE_PROJECT}.iam.gserviceaccount.com
echo "Make sure the GCP user SA has storage admin for fulling from GCR"
gcloud projects add-iam-policy-binding "${GOOGLE_PROJECT}" --member \
       "serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
       --role=roles/storage.admin || echo "Skipping changing SA since doesn't exist"


echo "Let's look at what's running:"
kubectl get all --all-namespaces

echo "Connecting to your kubeflow Jupyter note books"
echo "Step 1) Setting up port forwarding"
kubectl port-forward svc/jupyter -n kubeflow 8080:80 &
echo "Now it's your turn to launch the cloudshell web preview to port 8080"
echo "In ~20 minutes you should be able to access the webui at https://${G_KF_APP}.endpoints.${GOOGLE_PROJECT}.cloud.goog/"

