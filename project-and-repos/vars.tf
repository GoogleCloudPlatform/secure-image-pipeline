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

locals {
  services = toset(var.activate_apis)
}

variable "region" {
  description = "GCP Region"
}

variable "zone" {
  description = "GCP Zone"
}

variable "activate_apis" {
  description = "The list of apis to activate within the project"
  type        = list(string)
  default     = ["cloudfunctions.googleapis.com", "containerregistry.googleapis.com", "containeranalysis.googleapis.com", "containerscanning.googleapis.com", "run.googleapis.com", "cloudkms.googleapis.com", "compute.googleapis.com", "cloudbuild.googleapis.com", "stackdriver.googleapis.com", "artifactregistry.googleapis.com", "cloudapis.googleapis.com", "iam.googleapis.com", "cloudresourcemanager.googleapis.com", "iamcredentials.googleapis.com", "servicemanagement.googleapis.com", "serviceusage.googleapis.com", "storage-api.googleapis.com", "storage-component.googleapis.com", "sourcerepo.googleapis.com"]
}

variable "project_org_id" {
  description = "The organization ID."
  type        = string
}

variable "project_name" {
  description = "The name for the project"
  type        = string
  default     = "base-image"
}

variable "billing_account" {
  description = "The ID of the billing account to associate this project with"
  type        = string
}

#variable "project_folder_id" {
#  description = "The ID of a folder to host this project"
#  type        = string
#  default     = ""
#}

variable "labels" {
  description = "Map of labels for project"
  type        = map(string)
  default     = {}
}

variable "repos_visibility" {
  default = "private"
}

variable "gh_organization" {
  description = "GitHub Organization"
}

variable "gh_email" {
  description = "GitHub Email Addresss"
}

variable "gh_username" {
  description = "GitHub Username"
}
