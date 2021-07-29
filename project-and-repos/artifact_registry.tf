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

resource "google_artifact_registry_repository" "staging" {
  depends_on    = [google_project_service.staging]
  provider      = google-beta
  project       = google_project.staging.project_id
  location      = var.region
  repository_id = "staging-images"
  description   = "Container Image Repository - Staging"
  format        = "DOCKER"
}

resource "google_artifact_registry_repository" "verified" {
  depends_on    = [google_project_service.verified]
  provider      = google-beta
  project       = google_project.verified.project_id
  location      = var.region
  repository_id = "verified-images"
  description   = "Container Image Repository - Verified"
  format        = "DOCKER"
}

resource "google_artifact_registry_repository_iam_member" "staging" {
  provider   = google-beta
  project    = google_project.staging.project_id
  location   = var.region
  repository = google_artifact_registry_repository.staging.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_project.builder.number}@cloudbuild.gserviceaccount.com"
}

resource "google_artifact_registry_repository_iam_member" "verified" {
  provider   = google-beta
  project    = google_project.verified.project_id
  location   = var.region
  repository = google_artifact_registry_repository.verified.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_project.builder.number}@cloudbuild.gserviceaccount.com"
}

resource "google_container_registry" "staging" {
  depends_on = [google_project_service.staging]
  project  = google_project.staging.project_id
}

resource "google_container_registry" "verified" {
  depends_on = [google_project_service.verified]
  project  = google_project.verified.project_id
}

resource "google_storage_bucket_iam_member" "staging" {
  depends_on = [google_project_service.staging]
  bucket     = google_container_registry.staging.id
  role       = "roles/storage.admin"
  member     = "serviceAccount:${google_project.builder.number}@cloudbuild.gserviceaccount.com"
}

resource "google_storage_bucket_iam_member" "verified" {
  depends_on = [google_project_service.verified]
  bucket     = google_container_registry.verified.id
  role       = "roles/storage.admin"
  member     = "serviceAccount:${google_project.builder.number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "staging_analysis" {
  depends_on = [google_project_service.staging]
  project = google_project.staging.project_id
  role    = "roles/containeranalysis.occurrences.viewer"
  member  = "serviceAccount:${google_project.builder.number}-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "verified_analysis" {
  depends_on = [google_project_service.verified]
  project = google_project.verified.project_id
  role    = "roles/containeranalysis.occurrences.viewer"
  member  = "serviceAccount:${google_project.builder.number}-compute@developer.gserviceaccount.com"
}
