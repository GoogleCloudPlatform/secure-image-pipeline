#!/bin/bash
# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Bash safeties: exit on error, no unset variables, pipelines can't hide errors
set -o errexit
set -o pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

getancestry () {
    curl -X POST -H "Authorization: Bearer \"$(gcloud auth application-default print-access-token)\"" \
          -H "Content-Type: application/json; charset=utf-8" \
             https://cloudresourcemanager.googleapis.com/v1/projects/$1:getAncestry > ancestry.json
}

environment () {
  if [[ -f "$DIR/env.sh" ]]; then
    echo "Importing environment from $DIR/env.sh..." && . $DIR/env.sh
    export PARENT_FOLDER=${PARENT_ORGANIZATION}
  else
    echo "Please copy env.sh.tmpl into env.sh and edit..."
    exit 1
  fi
}

create_new_project(){
  echo "Creating new project for Base Image Factory..."
#  if [ "${PARENT_TYPE}" == "organization" ]; then
    gcloud projects create ${BASEIMGFCT_PROJECT} --organization=${PARENT_FOLDER} > /dev/null
#  else
#    gcloud projects create ${BASEIMGFCT_PROJECT} --folder=${PARENT_FOLDER} > /dev/null
#  fi
  gcloud beta billing projects link ${BASEIMGFCT_PROJECT} --billing-account=${BILLING_ACCOUNT} > /dev/null
}


get_project_number(){
  # There is sometimes a delay in the API and the gcloud command
  # Run the gcloud command until it returns a value
  continue=1
  while [[ ${continue} -gt 0 ]]
  do

  export BASEIMGFCT_PROJECTNUM=$(gcloud projects describe ${BASEIMGFCT_PROJECT} --format='value(projectNumber)')
  if [[ ${BASEIMGFCT_PROJECTNUM} ]]
  then continue=0
  fi

  done
}

baseimgfct_project_setup (){
  # Check that the Base Image Factorry Project has a billing account
  export BILLING_ACCOUNT=$(gcloud beta billing projects describe ${BASEIMGFCT_PROJECT} --format="value(billingAccountName)" | sed -e 's/.*\///g')

  if [[ ! ${BILLING_ACCOUNT} ]]
  then echo "Please enable billing account on ${BASEIMGFCT_PROJECT}" 
  exit
  fi

  export BASEIMGFCT_REGION=northamerica-northeast1

  echo "Setting up project for Base Image Factory..." 
  get_project_number
  gcloud config set project ${BASEIMGFCT_PROJECT};

  gcloud services enable cloudbilling.googleapis.com --project ${BASEIMGFCT_PROJECT} > /dev/null
  gcloud services enable cloudresourcemanager.googleapis.com --project ${BASEIMGFCT_PROJECT} > /dev/null
  gcloud services enable cloudbuild.googleapis.com --project ${BASEIMGFCT_PROJECT} > /dev/null
  gcloud services enable cloudkms.googleapis.com --project ${BASEIMGFCT_PROJECT} > /dev/null
  gcloud services enable containeranalysis.googleapis.com --project ${BASEIMGFCT_PROJECT} > /dev/null
  gcloud services enable iam.googleapis.com --project ${BASEIMGFCT_PROJECT} > /dev/null

  set +e
  gsutil ls gs://${BASEIMGFCT_BUCKET} 2>&1 > /dev/null

  if [ "$?" == "1" ]; then
    set -e
    gsutil mb -p ${BASEIMGFCT_PROJECT} -l ${BASEIMGFCT_REGION} gs://${BASEIMGFCT_BUCKET}/
    gcloud iam service-accounts create terraform-project-automation --project ${BASEIMGFCT_PROJECT} > /dev/null
  
    gcloud organizations add-iam-policy-binding ${PARENT_ORGANIZATION} \
      --member serviceAccount:terraform-project-automation@${BASEIMGFCT_PROJECT}.iam.gserviceaccount.com --role roles/browser > /dev/null
  
    gcloud organizations add-iam-policy-binding ${PARENT_ORGANIZATION} \
      --member serviceAccount:terraform-project-automation@${BASEIMGFCT_PROJECT}.iam.gserviceaccount.com --role roles/billing.user > /dev/null

    gcloud organizations add-iam-policy-binding ${PARENT_ORGANIZATION} \
      --member serviceAccount:terraform-project-automation@${BASEIMGFCT_PROJECT}.iam.gserviceaccount.com --role roles/resourcemanager.folderViewer > /dev/null

    gcloud projects add-iam-policy-binding ${BASEIMGFCT_PROJECT} \
      --member serviceAccount:terraform-project-automation@${BASEIMGFCT_PROJECT}.iam.gserviceaccount.com --role roles/storage.objectAdmin > /dev/null
  
    gcloud organizations add-iam-policy-binding ${PARENT_ORGANIZATION} \
      --member serviceAccount:terraform-project-automation@${BASEIMGFCT_PROJECT}.iam.gserviceaccount.com --role roles/billing.projectManager > /dev/null
  
    gcloud organizations add-iam-policy-binding ${PARENT_ORGANIZATION} \
      --member serviceAccount:terraform-project-automation@${BASEIMGFCT_PROJECT}.iam.gserviceaccount.com --role roles/resourcemanager.projectCreator

    gcloud iam service-accounts keys create ~/key.json \
    --iam-account terraform-project-automation@${BASEIMGFCT_PROJECT}.iam.gserviceaccount.com > /dev/null
    mkdir -p ./creds
    mv ~/key.json ./creds/gcp-sa.json
  fi
  set -e
}

project_prompt(){
  # Confirm project is the correct one to use for base images
  continue=1
  while [[ ${continue} -gt 0 ]]
  do

  # Prompt until project-id is correct
  if [[ ${BASEIMGFCT_PROJECT} ]]
  then read -p "Would you like to use ${BASEIMGFCT_PROJECT} to deploy a new base image factory? (y/n) :" yesno
  fi

  if [[ ${yesno} == "y" ]]
  then continue=0
  else read -p "Input project_id: " projectid
  export BASEIMGFCT_PROJECT=${projectid}
  fi

  done
}

github_prompt(){
  # Prompt until GitHub ORG is correct
  if [[ -z ${GH_ORG} ]]; then
    read -p "Input your GitHub Organization: " gh_org 
    export GH_ORG=${gh_org}
  fi

  if [[ -z ${GH_EMAIL} ]];then
    read -p "Input your GitHub email address: " gh_email
    export GH_EMAIL=${gh_email}
  fi
  
  if [[ -z ${GH_USER} ]]; then
    read -p "Input your GitHub username: " gh_user 
    export GH_USER=${gh_user}
  fi

}

write_tfvars(){
    cat > ${DIR}/project-and-repos/terraform.tfvars << EOF
project_org_id      = "${PARENT_ORGANIZATION}"
region              = "${BASEIMGFCT_REGION}"
zone                = "${BASEIMGFCT_REGION}-a"
project_folder_id   = "${PARENT_FOLDER}"
project_name        = "${BASEIMGFCT_PROJECT}"
billing_account     = "${BILLING_ACCOUNT}"

gh_organization     = "${GH_ORG}"
gh_email            = "${GH_EMAIL}"
gh_username         = "${GH_USER}"
EOF

    cat > ${DIR}/cloudbuild-and-automation/terraform.tfvars << EOF
fail_on = "critical"
container_images = ["ubuntu_18_0_4","alpine","centos","debian"]

vm_images = {
        "ubuntu_18_0_4" = "ubuntu-1804-bionic-v20210211"
}
EOF
}

write_backend(){
    cat >  ${DIR}/project-and-repos/backend.tf << EOF
terraform { 
  backend "gcs" {
    bucket      = "${BASEIMGFCT_BUCKET}"
    prefix      = "projects-and-repos/"
    credentials = "../creds/gcp-sa.json"
    }
  }
EOF
    cat >  ${DIR}/cloudbuild-and-automation/backend.tf << EOF
terraform { 
  backend "gcs" {
    bucket      = "${BASEIMGFCT_BUCKET}"
    prefix      = "cloudbuild-and-automation/"
    credentials = "../creds/gcp-sa.json"
    }
  }
EOF
}

write_data_source(){
  cat > $DIR/cloudbuild-and-automation/data.tf << EOF
data "terraform_remote_state" "projects_and_repos" {
  backend = "gcs"

  config = {
    bucket      = "${BASEIMGFCT_BUCKET}"
    prefix      = "projects-and-repos/"
    credentials = "../creds/gcp-sa.json"
  }
}
EOF
}

apply_projectrepos_tf(){
    cd ${DIR}/project-and-repos
    terraform init -reconfigure
    terraform apply -auto-approve
}

apply_cloudbuild_tf(){
    cd ${DIR}/cloudbuild-and-automation
    terraform init -reconfigure
    terraform apply -auto-approve
}
pause(){
 read -n1 -rsp $'Link your Github Repositories and press any key to continue or Ctrl+C to exit...\n'
}

link_gh_repos(){
    GH_REPO_INIT_URL="https://console.cloud.google.com/gcb-github-registration"
    python3 -m webbrowser ${GH_REPO_INIT_URL}
    pause
}


# # Main
github_prompt

echo "Setting up the environment..."
environment

read -p "Would you like to create a new Google Cloud Project for the base image factory? (y/n):" new_yesno
if [[ ${new_yesno} == "y" ]]
then 
    create_new_project
else 
    project_prompt
fi

baseimgfct_project_setup


##Setup DataSources, Backend + Terraform Variables
write_backend
write_data_source
write_tfvars
# Build Projects 
apply_projectrepos_tf
## Wait for Github/Cloudbuild Link
link_gh_repos
## Setup Cloudbuild + Cloud Functions
apply_cloudbuild_tf

echo ""
echo "Setup complete.  Your new base images will get staged here: ...."
