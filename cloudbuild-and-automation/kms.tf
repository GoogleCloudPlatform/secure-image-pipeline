/*******************************************
  KMS key ring creation
 *******************************************/
resource "random_id" "kms_ids" {
  byte_length = 4
}

resource "google_kms_key_ring" "pipeline_keyring" {
  name     = "pipeline-keyring-${random_id.kms_ids.dec}"
  project  = data.terraform_remote_state.projects_and_repos.outputs.google_project_builder.project_id
  location = "global"
}

resource "google_kms_crypto_key" "pipeline_key" {
  name     = "pipeline-key-${random_id.kms_ids.dec}"
  key_ring = google_kms_key_ring.pipeline_keyring.id
  purpose  = "ASYMMETRIC_SIGN"

  version_template {
    algorithm = "RSA_SIGN_PKCS1_4096_SHA512"
  }
}

resource "google_kms_crypto_key_iam_member" "voucher" {
  crypto_key_id = google_kms_crypto_key.pipeline_key.id
  role          = "roles/cloudkms.signer"
  member        = "serviceAccount:${data.terraform_remote_state.projects_and_repos.outputs.google_project_builder.number}-compute@developer.gserviceaccount.com"
}

# export KMS_RESOURCE_ID=projects/$PROJECT_ID/locations/global/keyRings/KEY_RING/cryptoKeys/KEY_NAME/cryptoKeyVersions/1