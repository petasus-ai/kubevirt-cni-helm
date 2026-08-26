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
  result=$(curl -sL --user "$ONOS_USER:$ONOS_PASSWORD" -w "%{http_code}" "http://$1:8181/onos/kubevirtnetworking/network" -o /dev/null || echo "curl_error")
  echo "$result"
}

while true; do
    sona_app_status=$(check_sona_app localhost)
    
    if [[ $sona_app_status == "curl_error" || $sona_app_status != "200" ]]; then
        echo "SONA NBI is not ready, retrying..."
        sleep 5
        continue
    else
        echo "SONA NBI is ready!"
        break
    fi
done

echo "Done, Bye!"
exit 0
