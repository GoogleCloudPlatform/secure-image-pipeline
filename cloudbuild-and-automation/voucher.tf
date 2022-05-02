resource "google_cloud_run_service" "voucher" {
  depends_on = [ null_resource.voucher_build ]
  name       = "voucher-server"
  location   = data.terraform_remote_state.projects_and_repos.outputs.region
  project    = data.terraform_remote_state.projects_and_repos.outputs.google_project_builder.project_id

  template {
    metadata {
      labels = {
        config-version = local_file.voucher_config.id
      }
    }
    spec {
      containers {
        image   = "gcr.io/${data.terraform_remote_state.projects_and_repos.outputs.google_project_builder.project_id}/voucher-server:latest"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "local_file" "voucher_config" {
    depends_on = [ null_resource.init_local_folder ]
    content     = templatefile("${path.module}/templates/config.toml.tpl",
                    {
                      fail_on      = var.fail_on
                      project_id   = data.terraform_remote_state.projects_and_repos.outputs.google_project_builder.project_id,
                      kms_key_name = "projects/${data.terraform_remote_state.projects_and_repos.outputs.google_project_builder.project_id}/locations/global/keyRings/${google_kms_key_ring.pipeline_keyring.name}/cryptoKeys/${google_kms_crypto_key.pipeline_key.name}/cryptoKeyVersions/1"
                    }
                  )
    filename = "${path.module}/temp/${data.terraform_remote_state.projects_and_repos.outputs.github_repository_containers.id}/voucher/tutorials/cloudrun/config.toml"
}

resource "null_resource" "voucher_build" {
  depends_on = [ null_resource.init_repos ]
  triggers = {
    config = local_file.voucher_config.id
  }
  provisioner "local-exec" {
    command = <<EOF
      cp ${path.module}/templates/Makefile.voucher.tpl ${path.module}/temp/${data.terraform_remote_state.projects_and_repos.outputs.github_repository_containers.id}/voucher/Makefile
      cp ${path.module}/templates/signer.go-template ${path.module}/temp/${data.terraform_remote_state.projects_and_repos.outputs.github_repository_containers.id}/voucher/v2/signer/kms/signer.go
      cd ${path.module}/temp/${data.terraform_remote_state.projects_and_repos.outputs.github_repository_containers.id}/voucher
      gcloud auth activate-service-account --project=${data.terraform_remote_state.projects_and_repos.outputs.google_project_builder.project_id} --key-file=../../../../creds/gcp-sa.json
      gcloud builds submit --config ./tutorials/cloudrun/cloudbuild-server.yaml
    EOF
  }
}

resource "google_service_account" "voucher_invoker" {
  project      = data.terraform_remote_state.projects_and_repos.outputs.google_project_builder.project_id
  account_id   = "voucher-invoker"
  display_name = "Voucher Invoker - Service Account"
}

resource "google_cloud_run_service_iam_member" "voucher_invoker" {
  location = google_cloud_run_service.voucher.location
  project  = data.terraform_remote_state.projects_and_repos.outputs.google_project_builder.project_id
  service  = google_cloud_run_service.voucher.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.voucher_invoker.email}"
}

resource "google_service_account_iam_member" "voucher_invoker" {
  service_account_id = google_service_account.voucher_invoker.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${data.terraform_remote_state.projects_and_repos.outputs.google_project_builder.number}@cloudbuild.gserviceaccount.com"
}

resource "google_artifact_registry_repository_iam_member" "voucher" {
  provider   = google-beta
  project    = data.terraform_remote_state.projects_and_repos.outputs.google_project_staging.project_id
  location   = data.terraform_remote_state.projects_and_repos.outputs.region
  repository = data.terraform_remote_state.projects_and_repos.outputs.google_artifact_registry_repository_staging.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${data.terraform_remote_state.projects_and_repos.outputs.google_project_builder.number}-compute@developer.gserviceaccount.com"
}

resource "google_artifact_registry_repository_iam_member" "voucher_invoker" {
  provider   = google-beta
  project    = data.terraform_remote_state.projects_and_repos.outputs.google_project_staging.project_id
  location   = data.terraform_remote_state.projects_and_repos.outputs.region
  repository = data.terraform_remote_state.projects_and_repos.outputs.google_artifact_registry_repository_staging.name
  role       = "roles/artifactregistry.reader"
  member   = "serviceAccount:${google_service_account.voucher_invoker.email}"
}

resource "google_container_analysis_note" "snakeoil" {
  name    = "snakeoil"
  project = data.terraform_remote_state.projects_and_repos.outputs.google_project_builder.project_id
  attestation_authority {
    hint {
      human_readable_name = "Staging - Voucher snakeoil check"
    }
  }
}

# NOTE_ID=snakeoil

# NOTE_URI=projects/$PROJECT_ID/notes/$NOTE_ID

# cat > /tmp/note_payload.json << EOM
# {
#   "name": "${NOTE_URI}",
#   "attestation": {
#     "hint": {
#       "human_readable_name": "voucher note for snakeoil check"
#     }
#   }
# }
# EOM

# curl -X POST \
#   -H "Content-Type: application/json" \
#   -H "Authorization: Bearer $(gcloud --project ${PROJECT_ID} auth print-access-token)"  \
#   -H "x-goog-user-project: ${PROJECT_ID}" \
#   --data-binary @/tmp/note_payload.json  \
# "https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/?noteId=${NOTE_ID}"
