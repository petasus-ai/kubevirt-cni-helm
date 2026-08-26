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

# Checking for the resolved IP address from the end of the command output. Refer
# the normal command output of nslookup to understand why.

while true
do
    resolvedIP=$(nslookup "$KUBERNETES_API" | awk -F':' '/^Address: / { matched = 1 } matched { print $2}' | xargs)
    if [[ -z "$resolvedIP" ]]
    then
        echo "$1" lookup failure
        sleep 5
        continue
    else
        echo "$1" resolved to "$resolvedIP"
        break
    fi
done

echo "Done, Bye!"

exit 0
