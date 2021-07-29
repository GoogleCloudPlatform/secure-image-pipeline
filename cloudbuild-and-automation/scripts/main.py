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

#This will trigger a named CloudBuild if a CVE fix
#has been detected for the named container

import base64
import json
import os
import hashlib
from google.auth.transport.requests import Request
from google.oauth2.id_token import fetch_id_token
from google.cloud.devtools import containeranalysis_v1
from google.cloud.devtools import cloudbuild
import google.oauth2.credentials
from google.auth.transport.requests import AuthorizedSession

def make_authorized_get_request(service_url):
    """
    make_authorized_get_request makes a GET request to the specified HTTP endpoint
    in service_url (must be a complete URL) by authenticating with the
    ID token obtained from the google-auth client library.
    """
    credentials, project = google.auth.default()
    authed_session = AuthorizedSession(credentials)

    response = authed_session.get(service_url)
    print(response.content)
    return response.content


def build_already_running(builds, trigger_id):
    """
    check to see if our build trigger is already running
    """
    for build in builds:
        if trigger_id == build.build_trigger_id:
            return True
    return False


def cve_trigger(event, context):
    """Triggered from a message on a Cloud Pub/Sub topic.
    Args:
         event (dict): Event payload.
         context (google.cloud.functions.Context): Metadata for the event.
    """
    #{"topic":"container-analysis-occurrences-v1","name":"projects/baseimgfct-oingo-staging-62/occurrences/806f4b88-a1e7-4f1f-a424-df79912804bb", "kind":"VULNERABILITY", "notificationTime":"2021-07-02T16:11:17.421306Z"}

    pubsub_message = json.loads(base64.b64decode(event['data']).decode('utf-8'))
    print(pubsub_message)

    
    if "VULNERABILITY" in pubsub_message['kind']:
        occurrence_id = os.path.basename(pubsub_message['name'])

        staging_project_id = os.environ['staging_project_id']
        builder_project_id = os.environ['builder_project_id']
        trigger_id = os.environ['trigger_id']
        registry = os.environ['registry']
        source = {"project_id":builder_project_id, "branch_name": "main"}

        client = containeranalysis_v1.ContainerAnalysisClient()
        grafeas_client = client.get_grafeas_client()
        parent = grafeas_client.occurrence_path(staging_project_id, occurrence_id)
        occurrence = grafeas_client.get_occurrence(request={"name":parent})
        print("occurrence.vulnerability.fix_available:%s\n"%occurrence.vulnerability.fix_available)
        # If this occurrence is on the registry we're watching and there's a fix available
        if registry in occurrence.resource_uri and occurrence.vulnerability.fix_available:
           image_digest = occurrence.resource_uri.split(':')[-1]
           print("image_digest:%s"%image_digest)
           service_url = 'https://www.googleapis.com/oauth2/v1/tokeninfo'
           print("service_url: %s\n"%service_url)
           resp = str(make_authorized_get_request(service_url),'utf-8')
           print(resp)
           service_url = 'https://gcr.io/v2/%s/manifests/latest' % (registry)
           print("service_url: %s\n"%service_url)
           resp = make_authorized_get_request(service_url)
           latest_digest = hashlib.sha256(resp).hexdigest()
           # And if the occurrence is on the latest image in our registry
           print(resp)
           if image_digest == latest_digest:
               cloudbuild_client = cloudbuild.CloudBuildClient()
               cb_request = {'project_id' : builder_project_id}
               builds = cloudbuild_client.list_builds(project_id=builder_project_id, filter='status="WORKING"')
               source = {"project_id":builder_project_id, "branch_name": "main"}
               if build_already_running(builds, trigger_id):
                  print("Build running, skipping: %s\n"%trigger_id)
               else:
                  print("Fix found, triggering: %s\n"%trigger_id)

                  cloudbuild_client.run_build_trigger(project_id = builder_project_id,
                                                     trigger_id = trigger_id, source = source)

