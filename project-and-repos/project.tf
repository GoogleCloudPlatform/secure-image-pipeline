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

/*******************************************
  Project creation
 *******************************************/
resource "random_id" "project_ids" {
  byte_length = 1
}

resource "google_project" "builder" {
  name                = "${var.project_name}-builder"
  project_id          = "${lower(replace(var.project_name, " ", "-"))}-builder-${random_id.project_ids.dec}"
  org_id              = var.project_org_id
  billing_account     = var.billing_account
  auto_create_network = true

  labels = var.labels
}

resource "google_project" "staging" {
  name                = "${var.project_name}-staging"
  project_id          = "${lower(replace(var.project_name, " ", "-"))}-staging-${random_id.project_ids.dec}"
  org_id              = var.project_org_id
  billing_account     = var.billing_account
  auto_create_network = true

  labels = var.labels
}

resource "google_project" "verified" {
  name                = "${var.project_name}-verified"
  project_id          = "${lower(replace(var.project_name, " ", "-"))}-verified-${random_id.project_ids.dec}"
  org_id              = var.project_org_id
  billing_account     = var.billing_account
  auto_create_network = true

  labels = var.labels
}

/*******************************************
  API enablement
 *******************************************/

resource "google_project_service" "builder" {
  for_each                   = local.services
  project                    = google_project.builder.project_id
  service                    = each.value
  disable_on_destroy         = false
  disable_dependent_services = false
}

resource "google_project_service" "staging" {
  for_each                   = local.services
  project                    = google_project.staging.project_id
  service                    = each.value
  disable_on_destroy         = false
  disable_dependent_services = false
}

resource "google_project_service" "verified" {
  for_each                   = local.services
  project                    = google_project.verified.project_id
  service                    = each.value
  disable_on_destroy         = false
  disable_dependent_services = false
}

# Permissions for Packer to manage disk images
resource "google_project_iam_member" "vm_staging" {
  depends_on = [ google_project_service.staging ]
  project    = google_project.staging.project_id
  role       = "roles/editor"
  member     = "serviceAccount:${google_project.builder.number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "vm_verified" {
  depends_on = [ google_project_service.verified ]
  project    = google_project.verified.project_id
  role       = "roles/editor"
  member     = "serviceAccount:${google_project.builder.number}@cloudbuild.gserviceaccount.com"
}
