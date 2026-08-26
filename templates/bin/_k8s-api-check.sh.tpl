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

# path of ServiceAccount Token
SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount

# read namespace
NAMESPACE=$(cat ${SERVICEACCOUNT}/namespace)

# service account bearer token
TOKEN=$(cat ${SERVICEACCOUNT}/token)

# internal certificate authority
CACERT=${SERVICEACCOUNT}/ca.crt

function check_k8s_api () {
  check_str='curl -ksL --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET -w "%{http_code}\\n" "https://$1/api" -o /dev/null'
  eval $check_str
}

check_k8s_api_str='check_k8s_api $KUBERNETES_API'

while true
do
    if [ $(eval $check_k8s_api_str) != "200" ];
    then
        echo "Kubernetes API server is not ready, retrying..."
	sleep 5
	continue
    else
	break
    fi
done

echo "Done, Bye!"

exit 0
