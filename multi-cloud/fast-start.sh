#!/bin/bash

# Long story, buy me a drink, we modify the PATH in here in previous installs.
# shellcheck disable=SC1090
source ~/.bashrc

set -ex

if [ ! -f helper.sh ]; then
  wget https://raw.githubusercontent.com/intro-to-ml-with-kubeflow/intro-to-ml-with-kubeflow-examples/master/multi-cloud/helper.sh
fi

source helper.sh


if [[ ! -z "$ENABLE_AZURE" ]]; then
  IF_AZURE="& Azure"
else
  SKIP_AZURE="1"
fi

set +x

echo "Prepairing to set up I will be deploying on:"
cecho "RED" "GCP${IF_AZURE}"
echo "Press enter if this OK or ctrl-d to change the settings"
echo "Azure is controlled with the ENABLE_AZURE env variable"
echo "p.s. did you remember to run me with tee?"
set -x
# shellcheck disable=2034
read -r panda

echo "Getting sudo cached..."
sudo ls

echo "Fetching cleanup script if not present"
if [ ! -f ~/cleanup.sh ]; then
  curl https://raw.githubusercontent.com/intro-to-ml-with-kubeflow/intro-to-ml-with-kubeflow-examples/master/multi-cloud/cleanup.sh -o ~/cleanup.sh
  chmod a+x cleanup.sh
fi


echo "Setting up SSH if needed"
if [ ! -f ~/.ssh/id_rsa.pub ]; then
    ssh-keygen
fi
echo "Installing some dependencies"
pip install --user pyyaml
echo "Downloading Kubeflow"
export KUBEFLOW_SRC=~/kf
export KUBEFLOW_TAG=v0.5.0
export KF_SCRIPTS=$KUBEFLOW_SRC/scripts
export PATH=$PATH:$KF_SCRIPTS
export KUBEFLOW_USERNAME=kf
export KUBEFLOW_PASSWORD=awesome
export KFCTL_RELEASE_BASE=https://github.com/kubeflow/kubeflow/releases/download/
if [ ! -d ~/kf ]; then
  mkdir -p $KUBEFLOW_SRC
  pushd $KUBEFLOW_SRC
  curl https://raw.githubusercontent.com/kubeflow/kubeflow/${KUBEFLOW_TAG}/scripts/download.sh | bash
  mkdir -p $KUBEFLOW_SRC
  pushd scripts
  wget ${KFCTL_RELEASE_BASE}${KUBEFLOW_TAG}/kfctl_${KUBEFLOW_TAG}_linux.tar.gz
  tar -xvf kfctl_${KUBEFLOW_TAG}_linux.tar.gz
  popd
  echo "export PATH=\$PATH:$KF_SCRIPTS" >> ~/.bashrc
  popd
fi
echo "Adding to the path"

echo "Downloading ksonnet"
export KSONNET_VERSION=0.13.1
PLATFORM=$(uname | tr '[:upper:]' '[:lower:]') # Either linux or darwin
export PLATFORM
if [ ! -d "ks_${KSONNET_VERSION}_${PLATFORM}_amd64" ]; then
  kubeflow_releases_base="https://github.com/ksonnet/ksonnet/releases/download"
  curl -OL "$kubeflow_releases_base/v${KSONNET_VERSION}/ks_${KSONNET_VERSION}_${PLATFORM}_amd64.tar.gz"
  tar zxf "ks_${KSONNET_VERSION}_${PLATFORM}_amd64.tar.gz"
  pwd=$(pwd)
  # Add this + platform/version exports to your bashrc or move the ks bin into /usr/bin
  export PATH=$PATH:"$pwd/ks_${KSONNET_VERSION}_${PLATFORM}_amd64"
  echo "export PATH=\$PATH:$pwd/ks_${KSONNET_VERSION}_${PLATFORM}_amd64" >> ~/.bashrc
fi


if ! command -v gcloud >/dev/null 2>&1; then
  CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
  export CLOUD_SDK_REPO
  echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  sudo apt-get update && sudo apt-get install google-cloud-sdk
fi

echo "Configuring Google default project if unset"

if ! GOOGLE_PROJECT=$(gcloud config get-value project 2>/dev/null) ||
     [ -z "$GOOGLE_PROJECT" ]; then
  echo "Default project not configured. Press enter to auto-configure or Ctrl-D to exit"
  echo "and change the project you're in up above (or manually set)"
  # shellcheck disable=SC2034
  read -r configure
  latest_project=$(gcloud projects list | tail -n 1 | cut -f 1  -d' ')
  gcloud config set project "$latest_project"
  echo "gcloud config set project \"$latest_project\"" >> ~/.bashrc
fi
GOOGLE_PROJECT=$(gcloud config get-value project 2>/dev/null)
echo "export GOOGLE_PROJECT=$GOOGLE_PROJECT" >> ~/.bashrc


echo "Enabling Google Cloud APIs async for speedup"
gcloud services enable file.googleapis.com storage-component.googleapis.com \
       storage-api.googleapis.com stackdriver.googleapis.com containerregistry.googleapis.com \
       iap.googleapis.com compute.googleapis.com container.googleapis.com &
gke_api_enable_pid=$?
if [[ -z "$SKIP_AZURE" ]]; then
  echo "Setting up Azure"
  if ! command -v az >/dev/null 2>&1; then
    sudo apt-get install apt-transport-https lsb-release software-properties-common dirmngr -y
    AZ_REPO=$(lsb_release -cs)
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
      sudo tee /etc/apt/sources.list.d/azure-cli.list
    sudo apt-key --keyring /etc/apt/trusted.gpg.d/Microsoft.gpg adv \
	 --keyserver packages.microsoft.com \
	 --recv-keys BC528686B50D79E339D3721CEB3E94ADBE1229CF
    sudo apt-get update
    sudo apt-get install azure-cli
    az login
  fi
  echo "Setting up Azure resource group"
  az configure --defaults location=westus
  az group exists -n kf-westus || az group create -n kf-westus
else
  echo "Skipping Azure setup since configured as such"
fi


echo "Creating bucket"
export BUCKET_NAME=kubeflow-${GOOGLE_PROJECT}
echo "export BUCKET_NAME=kubeflow-${GOOGLE_PROJECT}" >> ~/.bashrc
gsutil mb -c regional -l us-central1 "gs://${BUCKET_NAME}" || echo "Bucket exists"

echo "Creating Google Kubeflow project:"
export G_KF_APP=${G_KF_APP:="g-kf-app"}
export ZONE=${ZONE:="us-central1-a"}
export GZONE=$ZONE
echo "export G_KF_APP=$G_KF_APP" >> ~/.bashrc


echo "export PATH=~/:\$PATH" >> ~/.bashrc

echo "When you are ready to connect to your Azure cluster run:"
echo "az aks get-credentials --name azure-kf-test --resource-group westus"
echo "All done!"
echo "Remember to source your bash rc with:"
cecho "RED" "source ~/.bashrc"
