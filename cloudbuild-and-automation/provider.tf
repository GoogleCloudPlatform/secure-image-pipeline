terraform {
  required_providers {
    github = {
      source = "integrations/github"
      version = "4.3.0"
    }
  }
}

provider "google" {
  region = data.terraform_remote_state.projects_and_repos.outputs.region
  credentials = file("../creds/gcp-sa.json")
}

provider "google-beta" {
  region = data.terraform_remote_state.projects_and_repos.outputs.region
  credentials = file("../creds/gcp-sa.json")
}

provider "github" {
  organization = data.terraform_remote_state.projects_and_repos.outputs.gh_organization
}