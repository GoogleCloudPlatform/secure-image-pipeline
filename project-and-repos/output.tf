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


# project_id for builder project
# github repo id for containers and vm
# github branch staging for containers and vm
# github repo ssh clone url for containers and vm
# var output for gh_email, gh_username, region
# deploy_key filename for containers and vm

output "google_project_builder" {
    value = google_project.builder
}

output "google_project_staging" {
    value = google_project.staging
}

output "google_project_verified" {
    value = google_project.verified
}

output "github_repository_containers" {
    value = github_repository.containers
}

output "google_artifact_registry_repository_staging" {
    value = google_artifact_registry_repository.staging
}

output "google_artifact_registry_repository_verified" {
    value = google_artifact_registry_repository.verified
}

output "gh_email" {
    value = var.gh_email
}

output "gh_username" {
    value = var.gh_username
}

output "gh_organization" {
    value = var.gh_organization
}

output "region" {
    value = var.region
}

output "zone" {
    value = var.zone
}

output "deploy_key_containers_ssh" {
    value = local_file.containers_ssh.filename
}
