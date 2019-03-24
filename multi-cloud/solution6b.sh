#!/bin/bash

set -ex

# Make a tensorflow job
ks generate tf-job-simple-v1beta1 tfjob-2 --name tfjob-issue-summarization-2
# Configure the job
ks param set tfjob-2 gcpSecretName "user-gcp-sa"
ks param set tfjob-2 gcpSecretFile "user-gcp-sa.json"
# Use the pre-built image, you can override with your own
# Look at
# https://github.com/kubeflow/examples/tree/master/github_issue_summarization/notebooks
ks param set tfjob-2 image "gcr.io/kubeflow-examples/tf-job-issue-summarization:v20180629-v0.1-2-g98ed4b4-dirty-182929"
ks param set tfjob-2 input_data "gs://kubeflow-examples/github-issue-summarization-data/github_issues_sample.csv"
ks param set tfjob-2 input_data_gcs_bucket "kubeflow-examples"
ks param set tfjob-2 input_data_gcs_path "github-issue-summarization-data/github-issues.zip"
ks param set tfjob-2 num_epochs "7"
ks param set tfjob-2 output_model "/tmp/model.h5"
ks param set tfjob-2 output_model_gcs_bucket "${BUCKET_NAME}"
ks param set tfjob-2 output_model_gcs_path "github-issue-summarization-data"
ks param set tfjob-2 sample_size "100000"
# Run the job
ks apply default -c tfjob-2
