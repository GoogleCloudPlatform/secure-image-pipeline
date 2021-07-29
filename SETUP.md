# Setup for the automation

## The easy path
```shell
./setup.sh
```

## What's happening

The setup.sh script needs you to have permissions to administer your GCP Organization's IAM policies,
and create projects.  It will use your current project to find information about your parent
Organization and Billing Account info, and then use that to create a new project, enable APIs,
enable billing, and create IAM policies for the terraform work ahead.

### Manual setup
If the set up script is not working for you, you can customize the instructions below:

```shell
export PROJECT=<project-id>
gcloud config set account tim.fairweather@arctiq.ca
gcloud services enable cloudbilling.googleapis.com --project ${PROJECT}
gcloud services enable cloudresourcemanager.googleapis.com --project ${PROJECT}
gcloud services enable cloudbuild.googleapis.com --project ${PROJECT}
gcloud services enable cloudkms.googleapis.com --project ${PROJECT}
gcloud services enable containeranalysis.googleapis.com --project ${PROJECT}


gsutil mb -p ${PROJECT} -l northamerica-northeast1 gs://${PROJECT}-pipeline-work/
gcloud iam service-accounts create terraform-project-automation --project ${PROJECT}
gcloud organizations add-iam-policy-binding 725616416277 \
    --member serviceAccount:terraform-project-automation@${PROJECT}.iam.gserviceaccount.com --role roles/browser
gcloud organizations add-iam-policy-binding 725616416277 \
    --member serviceAccount:terraform-project-automation@${PROJECT}.iam.gserviceaccount.com --role roles/billing.user
gcloud organizations add-iam-policy-binding 725616416277 \
    --member serviceAccount:terraform-project-automation@${PROJECT}.iam.gserviceaccount.com --role roles/billing.viewer
gcloud organizations add-iam-policy-binding 725616416277 \
    --member serviceAccount:terraform-project-automation@${PROJECT}.iam.gserviceaccount.com --role roles/resourcemanager.projectCreator
gcloud organizations add-iam-policy-binding 725616416277 \
    --member serviceAccount:terraform-project-automation@${PROJECT}.iam.gserviceaccount.com --role roles/resourcemanager.folderViewer
gcloud projects add-iam-policy-binding ${PROJECT} \
    --member serviceAccount:terraform-project-automation@${PROJECT}.iam.gserviceaccount.com --role roles/storage.objectAdmin
gcloud iam service-accounts keys create ~/key.json \
  --iam-account terraform-project-automation@${PROJECT}.iam.gserviceaccount.com
mv ~/key.json ./creds/gcp-sa.json
```

## GitHub Personal Account Token Setup
```shell

```

## Fetch json key from Vault
```shell
vault kv get -field="gcp-sa.json" arctiq/shared/projects/p-google-cicd-pipeline-work > creds/gcp-sa.json
```
