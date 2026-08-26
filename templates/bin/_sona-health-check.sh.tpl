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
  check_str='curl -sL --user $ONOS_USER:$ONOS_PASSWORD -w "%{http_code}\\n" "http://$1:8181/onos/kubevirtnode/node/healthz" -o /dev/null'
  eval $check_str
}

function check_sona_health_result () {
  check_str='curl -sL --user $ONOS_USER:$ONOS_PASSWORD "http://$1:8181/onos/kubevirtnode/node/healthz"'
  eval $check_str
}

check_sona_health_str='check_sona_health localhost'
check_sona_health_result_str='check_sona_health_result localhost'

if [ $(eval $check_sona_health_str) != "200" ];
then
    echo "health check endpoint is not available!"
    exit 1
fi

if [[ $(eval $check_sona_health_result_str) != *"ok"* ]];
then
    echo "health check endpoint returns not OK!"
    exit 1
fi

echo "Health check endpoint returns OK!"

exit 0
