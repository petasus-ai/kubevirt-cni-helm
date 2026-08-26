#!/bin/bash
{{/*
Copyright 2021-present SK Telecom
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/}}

set -x

ONOS_USER="onos"
ONOS_PASSWORD="rocks"

function check_sona_health () {
  result=$(curl -sL --user "$ONOS_USER:$ONOS_PASSWORD" -w "%{http_code}" "http://$1:8181/onos/kubevirtnode/node/healthz" -o /dev/null || echo "curl_error")
  echo "$result"
}

function check_sona_health_result () {
  result=$(curl -sL --user "$ONOS_USER:$ONOS_PASSWORD" "http://$1:8181/onos/kubevirtnode/node/healthz" || echo "curl_error")
  echo "$result"
}

# Checking health HTTP status
health_status=$(check_sona_health "localhost")
if [[ $health_status == "curl_error" || $health_status != "200" ]]; then
    echo "Health check endpoint is not available or curl error occurred!"
    exit 1
fi

# Checking health content
health_content=$(check_sona_health_result "localhost")
if [[ $health_content == "curl_error" || $health_content != *"ok"* ]]; then
    echo "Health check endpoint returns not OK or curl error occurred!"
    exit 1
fi

echo "Health check endpoint returns OK!"
exit 0
