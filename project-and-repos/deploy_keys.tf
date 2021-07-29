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

resource "tls_private_key" "containers" {
  algorithm = "RSA"
}

resource "tls_private_key" "vm" {
  algorithm = "RSA"
}

resource "github_repository_deploy_key" "containers" {
  title      = "${var.project_name} key"
  repository = github_repository.containers.id
  key        = tls_private_key.containers.public_key_openssh
  read_only  = "false"
}

resource "local_file" "containers_ssh" {
  filename        = "../creds/github_containers_ssh"
  content         = tls_private_key.containers.private_key_pem
  file_permission = "0600"
}
