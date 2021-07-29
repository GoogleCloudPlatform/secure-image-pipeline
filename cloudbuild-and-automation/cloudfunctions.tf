data "google_pubsub_topic" "container_scanning" {
  project = data.terraform_remote_state.projects_and_repos.outputs.google_project_staging.project_id
  name    = "container-analysis-occurrences-v1"
  depends_on = [ null_resource.submit_builds_gcr ]
}

resource "random_id" "bucket_ids" {
  byte_length = 4
}

resource "google_storage_bucket" "functions" {
  project = data.terraform_remote_state.projects_and_repos.outputs.google_project_staging.project_id
  name    = "container-functions-${random_id.bucket_ids.dec}"
}

resource "google_storage_bucket_iam_member" "member" {
  bucket = google_storage_bucket.functions.name
  role = "roles/storage.objectViewer"
  member = "allUsers"
}
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/scripts/"
  output_path ="${path.module}/scripts/index.zip"
}
resource "google_storage_bucket_object" "functions" {
  name   = "index.zip"
  bucket = google_storage_bucket.functions.name
  source = data.archive_file.function_zip.output_path
}


resource "google_cloudfunctions_function" "function" {
  for_each =    google_cloudbuild_trigger.staging_fixfound
  depends_on  = [ google_storage_bucket_iam_member.member, google_cloudbuild_trigger.staging_fixfound ]
  project     = data.terraform_remote_state.projects_and_repos.outputs.google_project_staging.project_id
  name        = "container-scanning-function-${each.key}"
  description = "Function to trigger container builds based off of CVE fixes found"
  runtime     = "python37"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.functions.name
  source_archive_object = google_storage_bucket_object.functions.name
  event_trigger {
    event_type     = "google.pubsub.topic.publish"
    resource       = data.google_pubsub_topic.container_scanning.name
  }
  timeout               = 60
  entry_point           = "cve_trigger"
  environment_variables = {
    staging_project_id =  data.terraform_remote_state.projects_and_repos.outputs.google_project_staging.project_id
    builder_project_id =  data.terraform_remote_state.projects_and_repos.outputs.google_project_builder.project_id
    trigger_id         =  each.value.trigger_id
    registry           =  "${data.terraform_remote_state.projects_and_repos.outputs.google_project_staging.project_id}/${each.key}"
  }
}

