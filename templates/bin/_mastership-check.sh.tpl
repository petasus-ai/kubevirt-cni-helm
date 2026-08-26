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

function check_mastership () {
  check_str='curl -sL -w "%{http_code}\\n" "http://$1:$2/" -o /dev/null'
  eval $check_str
}

function check_mastership_result() {
  check_str='curl "http://$1:$2/"'
  eval $check_str
}

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
    if [[ $(eval $check_mastership_result_str) != *"$MY_POD_NAME"* ]];
    then
        echo "The mastership role is standby, wait..."
        sleep 5
        continue
    else
        echo "The mastership role is master!"
        break
    fi
done

echo "Done, Bye!"

exit 0
