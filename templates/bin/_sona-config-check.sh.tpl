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
  check_str='curl -sL --user $ONOS_USER:$ONOS_PASSWORD --max-time 30 -w "%{http_code}\\n" "http://$1:8181/onos/kubevirtnode/node/healthz" -o /dev/null'
  eval $check_str
}

function check_sona_health_result () {
  check_str='curl -sL --user $ONOS_USER:$ONOS_PASSWORD "http://$1:8181/onos/kubevirtnode/node/healthz"'
  eval $check_str
}

function check_mastership () {
  check_str='curl -sL --max-time 30 -w "%{http_code}\\n" "http://$1:$2/" -o /dev/null'
  eval $check_str
}

function check_mastership_result() {
  check_str='curl "http://$1:$2/"'
  eval $check_str
}

check_sona_health_str='check_sona_health localhost'
check_sona_health_result_str='check_sona_health_result localhost'
check_mastership_str='check_mastership localhost {{ .Values.leader.port }}'
check_mastership_result_str='check_mastership_result localhost {{ .Values.leader.port }}'

while true
do
    if [ $(eval $check_mastership_str) != "200" ];
    then
        echo "Leader elector is not ready..."
	sleep 5
	continue
    else
        echo "Leader elector is ready now!"
	break
    fi
done

while true
do
    if [ $(eval $check_sona_health_str) != "200" ];
    then
        echo "health check endpoint is not available"
        sleep 5
        continue
    else
        echo "health check endpoint is ready now!"
        break
    fi
done

role="standby"
if [[ $(eval $check_mastership_result_str) == *"$MY_POD_NAME"* ]];
then       
    echo "The mastership role is master!"
    role="master"
fi

status="error"
if [[ $(eval $check_sona_health_result_str) == *"ok"* ]];
then
    echo "health check endpoint returns OK!"
    status="ok"
fi

if [[ $role == "master" && $status == "error" ]]
then
    echo "Master node has empty api config, restart..."
    exit 1
fi

echo "Done, Bye!"

exit 0
