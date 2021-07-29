variable "container_images" {
  type = list
}

variable "fail_on" {
  type = string
}

locals {
  services = toset(var.activate_apis)
}
variable "activate_apis" {
  description = "The list of apis to activate within the project"
  type        = list(string)
  default     = ["cloudfunctions.googleapis.com", "containerregistry.googleapis.com", "containeranalysis.googleapis.com", "containerscanning.googleapis.com", "run.googleapis.com", "cloudkms.googleapis.com", "compute.googleapis.com", "cloudbuild.googleapis.com", "stackdriver.googleapis.com", "artifactregistry.googleapis.com", "cloudapis.googleapis.com", "iam.googleapis.com", "cloudresourcemanager.googleapis.com", "iamcredentials.googleapis.com", "servicemanagement.googleapis.com", "serviceusage.googleapis.com", "storage-api.googleapis.com", "storage-component.googleapis.com", "sourcerepo.googleapis.com"]
}
