resource "google_cloudbuild_trigger" "staging_pr" {
  depends_on  = [ null_resource.init_repos ]
  for_each    = toset(var.container_images)
  provider    = google-beta
  project     = data.terraform_remote_state.projects_and_repos.outputs.google_project_builder.project_id
  description = "Pull Request on ${each.value} Containers - Staging"
  github {
    owner = data.terraform_remote_state.projects_and_repos.outputs.gh_organization
    name = data.terraform_remote_state.projects_and_repos.outputs.github_repository_containers.id
    // push {
    //   branch = data.terraform_remote_state.projects_and_repos.outputs.github_branch_containers_staging.branch
    // }
    pull_request {
      branch = "main"
      comment_control = "COMMENTS_ENABLED"
    }
  }

  substitutions = {
    _IMG             = each.value
    _SERVICE_URL     = google_cloud_run_service.voucher.status[0].url
    _SERVICE_ACCOUNT = google_service_account.voucher_invoker.email
    ## GCR-based
    _IMG_DEST        = "gcr.io/${data.terraform_remote_state.projects_and_repos.outputs.google_project_staging.project_id}/${each.value}"
    ## Artifact Registry-based
    # _IMG_DEST        = "${data.terraform_remote_state.projects_and_repos.outputs.google_artifact_registry_repository_staging.location}-docker.pkg.dev/${data.terraform_remote_state.projects_and_repos.outputs.google_project_staging.project_id}/${data.terraform_remote_state.projects_and_repos.outputs.google_artifact_registry_repository_staging.name}/${each.value}"
  }

  filename = "${each.value}/cloudbuild-staging.yaml"

  included_files = [ "${each.value}/**" ]
}

resource "google_cloudbuild_trigger" "staging_fixfound" {
  depends_on  = [ null_resource.init_repos ]
  for_each    = toset(var.container_images)
  provider    = google-beta
  project     = data.terraform_remote_state.projects_and_repos.outputs.google_project_builder.project_id
  description = "Fix Found on ${each.value} Containers - Staging"
  github {
    owner = data.terraform_remote_state.projects_and_repos.outputs.gh_organization
    name = data.terraform_remote_state.projects_and_repos.outputs.github_repository_containers.id
    pull_request {
      branch = "main"
      comment_control = "COMMENTS_ENABLED"
    }
  }

  substitutions = {
    _IMG             = each.value
    _SERVICE_URL     = google_cloud_run_service.voucher.status[0].url
    _SERVICE_ACCOUNT = google_service_account.voucher_invoker.email
    ## GCR-based
    _IMG_DEST        = "gcr.io/${data.terraform_remote_state.projects_and_repos.outputs.google_project_staging.project_id}/${each.value}"
    ## Artifact Registry-based
    # _IMG_DEST        = "${data.terraform_remote_state.projects_and_repos.outputs.google_artifact_registry_repository_staging.location}-docker.pkg.dev/${data.terraform_remote_state.projects_and_repos.outputs.google_project_staging.project_id}/${data.terraform_remote_state.projects_and_repos.outputs.google_artifact_registry_repository_staging.name}/${each.value}"
  }

  filename = "${each.value}/cloudbuild-staging.yaml"

  included_files = [ "${each.value}/**" ]
}

resource "google_cloudbuild_trigger" "verified" {
  depends_on  = [ null_resource.init_repos ]
  for_each    = toset(var.container_images)
  provider    = google-beta
  project     = data.terraform_remote_state.projects_and_repos.outputs.google_project_builder.project_id
  description = "Merge to main for ${each.value} Containers - Verified"
  github {
    owner = data.terraform_remote_state.projects_and_repos.outputs.gh_organization
    name = data.terraform_remote_state.projects_and_repos.outputs.github_repository_containers.id
    push {
      branch = "main"
    }
  }

  substitutions = {
    ## GCR-based
    _STAGING_IMG  = "gcr.io/${data.terraform_remote_state.projects_and_repos.outputs.google_project_staging.project_id}/${each.value}"
    _VERIFIED_IMG  = "gcr.io/${data.terraform_remote_state.projects_and_repos.outputs.google_project_verified.project_id}/${each.value}"
    ## Artifact Registry-based
    # _STAGING_IMG = "${data.terraform_remote_state.projects_and_repos.outputs.google_artifact_registry_repository_staging.location}-docker.pkg.dev/${data.terraform_remote_state.projects_and_repos.outputs.google_project_staging.project_id}/${data.terraform_remote_state.projects_and_repos.outputs.google_artifact_registry_repository_staging.name}/${each.value}"
    # _VERIFIED_IMG = "${data.terraform_remote_state.projects_and_repos.outputs.google_artifact_registry_repository_verified.location}-docker.pkg.dev/${data.terraform_remote_state.projects_and_repos.outputs.google_project_verified.project_id}/${data.terraform_remote_state.projects_and_repos.outputs.google_artifact_registry_repository_verified.name}/${each.value}"
  }

  filename = "${each.value}/cloudbuild-verified.yaml"

  included_files = [ "${each.value}/**" ]
}

# northamerica-northeast1-docker.pkg.dev
