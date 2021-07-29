data "archive_file" "init" {
  depends_on  = [ null_resource.copy_folders ]
  type        = "zip"
  source_dir  = "${path.module}/temp/${data.terraform_remote_state.projects_and_repos.outputs.github_repository_containers.id}"
  output_path = "${path.module}/temp/init.zip"
}

resource "null_resource" "init_local_folder" {
  provisioner "local-exec" {
    command = <<EOF
      mkdir -p ${path.module}/temp
      cd ${path.module}/temp
      GIT_SSH_COMMAND='ssh -i ${path.module}/../${data.terraform_remote_state.projects_and_repos.outputs.deploy_key_containers_ssh} -o StrictHostKeyChecking=no' git clone ${data.terraform_remote_state.projects_and_repos.outputs.github_repository_containers.ssh_clone_url}
      git config user.email "${data.terraform_remote_state.projects_and_repos.outputs.gh_email}"
      git config user.name "${data.terraform_remote_state.projects_and_repos.outputs.gh_username}"
      cd ${data.terraform_remote_state.projects_and_repos.outputs.github_repository_containers.id}
      git submodule add https://github.com/grafeas/voucher.git
      git add .
      git commit -m "add voucher"
      GIT_SSH_COMMAND='ssh -i ${path.module}/../../${data.terraform_remote_state.projects_and_repos.outputs.deploy_key_containers_ssh} -o StrictHostKeyChecking=no' git push
    EOF
  }
  provisioner "local-exec" {
    when = destroy
    command = <<EOF
      rm -rf ${path.module}/temp
    EOF
  }
}

resource "null_resource" "copy_folders" {
  depends_on = [ null_resource.init_local_folder ]
  for_each = toset(var.container_images)
  provisioner "local-exec" {
    command = <<EOF
      cp -rp ${path.module}/container_repo/${each.value} ${path.module}/temp/${data.terraform_remote_state.projects_and_repos.outputs.github_repository_containers.id}/
    EOF
  }
}

resource "null_resource" "init_repos" {
  depends_on = [ null_resource.copy_folders,local_file.voucher_config ]
  triggers = {
    folders_md5 = data.archive_file.init.output_md5
  }
  provisioner "local-exec" {
    command = <<EOF
      cd ${path.module}/temp/${data.terraform_remote_state.projects_and_repos.outputs.github_repository_containers.id}
      git add *
      git commit -m "Terraform Update"
      GIT_SSH_COMMAND='ssh -i ${path.module}/../../${data.terraform_remote_state.projects_and_repos.outputs.deploy_key_containers_ssh} -o StrictHostKeyChecking=no' git push
      uptime
    EOF
  }
}

resource "null_resource" "submit_builds_gcr" {
  depends_on = [ google_cloudbuild_trigger.staging_pr, google_cloudbuild_trigger.verified ]
  for_each = toset(var.container_images)
  provisioner "local-exec" {
    command = <<EOF
      cd ${path.module}/temp/${data.terraform_remote_state.projects_and_repos.outputs.github_repository_containers.id}
      gcloud auth activate-service-account --project=${data.terraform_remote_state.projects_and_repos.outputs.google_project_builder.project_id} --key-file=../../../creds/gcp-sa.json
      gcloud builds submit --config ${each.value}/cloudbuild-staging.yaml --substitutions _IMG="${each.value}",_IMG_DEST="gcr.io/${data.terraform_remote_state.projects_and_repos.outputs.google_project_staging.project_id}/${each.value}",SHORT_SHA="initial",_SERVICE_URL="${google_cloud_run_service.voucher.status[0].url}",_SERVICE_ACCOUNT="${google_service_account.voucher_invoker.email}" .
      gcloud builds submit --config ${each.value}/cloudbuild-staging.yaml --substitutions _IMG="${each.value}",_IMG_DEST="gcr.io/${data.terraform_remote_state.projects_and_repos.outputs.google_project_verified.project_id}/${each.value}",SHORT_SHA="initial",_SERVICE_URL="${google_cloud_run_service.voucher.status[0].url}",_SERVICE_ACCOUNT="${google_service_account.voucher_invoker.email}" .
    EOF
  }
}

# resource "null_resource" "submit_builds_ar" {
#   depends_on = [ google_cloudbuild_trigger.staging_pr, google_cloudbuild_trigger.verified ]
#   for_each = toset(var.container_images)
#   provisioner "local-exec" {
#     command = <<EOF
#       cd ${path.module}/temp/${data.terraform_remote_state.projects_and_repos.outputs.github_repository_containers.id}
#       gcloud auth activate-service-account --project=${data.terraform_remote_state.projects_and_repos.outputs.google_project_builder.project_id} --key-file=../../../creds/gcp-sa.json
#       gcloud builds submit --config ${each.value}/cloudbuild-staging.yaml --substitutions _IMG="${each.value}",_IMG_DEST="gcr.io/${data.terraform_remote_state.projects_and_repos.outputs.google_project_staging.project_id}/${each.value}",SHORT_SHA="initial",_SERVICE_URL="${google_cloud_run_service.voucher.status[0].url}",_SERVICE_ACCOUNT="${google_service_account.voucher_invoker.email}" .
#       gcloud builds submit --config ${each.value}/cloudbuild-staging.yaml --substitutions _IMG="${each.value}",_IMG_DEST="gcr.io/${data.terraform_remote_state.projects_and_repos.outputs.google_project_verified.project_id}/${each.value}",SHORT_SHA="initial",_SERVICE_URL="${google_cloud_run_service.voucher.status[0].url}",_SERVICE_ACCOUNT="${google_service_account.voucher_invoker.email}" .
#     EOF
#   }
# }
