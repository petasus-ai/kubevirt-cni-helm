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

function check_sona_app () {
  result=$(curl -sL --user "$ONOS_USER:$ONOS_PASSWORD" -w "%{http_code}" "http://$1:8181/onos/kubevirtnetworking/network" -o /dev/null || true)
  echo "${result:-curl_error}"
}

function check_sona_health () {
  result=$(curl -sL --user "$ONOS_USER:$ONOS_PASSWORD" -w "%{http_code}" "http://$1:8181/onos/kubevirtnode/node/healthz" -o /dev/null || true)
  echo "${result:-curl_error}"
}

function check_sona_health_result () {
  result=$(curl -sL --user "$ONOS_USER:$ONOS_PASSWORD" "http://$1:8181/onos/kubevirtnode/node/healthz" || true)
  echo "${result:-curl_error}"
}

function check_mastership () {
  result=$(curl -sL -w "%{http_code}" "http://$1:$2/" -o /dev/null || true)
  echo "${result:-curl_error}"
}

function check_mastership_result () {
  result=$(curl -sL "http://$1:$2/" || true)
  echo "${result:-curl_error}"
}

# Check SONA app availability
sona_app_status=$(check_sona_app localhost)
if [[ $sona_app_status == "curl_error" || $sona_app_status != "200" ]]; then
    echo "SONA app is not available, retry to restart."
    exit 1
fi

# Check leader elector readiness
mastership_status=$(check_mastership localhost {{ .Values.leader.port }})
if [[ $mastership_status == "curl_error" || $mastership_status != "200" ]]; then
    echo "Leader elector is not ready, restart..."
    exit 1
fi

# Check health endpoint availability
health_status=$(check_sona_health localhost)
if [[ $health_status == "curl_error" || $health_status != "200" ]]; then
    echo "Health check endpoint is not available, restart..."
    exit 1
fi

# Determine role
role="standby"
mastership_result=$(check_mastership_result localhost {{ .Values.leader.port }})
if [[ $mastership_result == *"$MY_POD_NAME"* ]]; then
    role="master"
fi

# Determine status
status="error"
sona_health_result=$(check_sona_health_result localhost)
if [[ $sona_health_result == "curl_error" ]]; then
    echo "Failed to fetch health check result, restart..."
    exit 1
fi

if [[ $sona_health_result == *"ok"* ]]; then
    status="ok"
fi

# Validate standby role with error status
if [[ $role == "standby" && $status == "ok" ]]; then
    echo "Standby controller should not have API config inserted, restart..."
    exit 1
fi

exit 0

