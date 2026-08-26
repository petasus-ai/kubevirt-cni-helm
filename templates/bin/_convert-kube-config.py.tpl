#!/usr/bin/env python
{{/*
Copyright 2020-present SK Telecom
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

import json, yaml, sys, getopt, os

def main(argv):
    inputfile = ''
    outputfile = ''
    try:
       opts, args = getopt.getopt(argv,"ht:i:o:",["ifile=","ofile="])
    except getopt.GetoptError:
       print ('convert-kube-config.py -i <inputfile> -o <outputfile>')
       sys.exit(2)

    for opt, arg in opts:
       if opt == '-h':
          print ('convert-kube-config.py -i <inputfile> -o <outputfile>')
          sys.exit()
       elif opt in ("-i", "--ifile"):
          inputfile = arg
       elif opt in ("-o", "--ofile"):
          outputfile = arg

    with open(inputfile, 'r') as stream:
        try:
            raw = yaml.safe_load(stream)
            clusters = raw["clusters"]
            cluster = clusters[0]["cluster"]
            ca_cert_data = cluster["certificate-authority-data"]
            server = cluster["server"]
            scheme = server.split(":")[0].upper()
            ip_address = server.split(":")[1].replace('//', '')
            port = server.split(":")[2]

            users = raw["users"]
            user = users[0]["user"]
            client_cert_data = user["client-certificate-data"]
            client_key_data = user["client-key-data"]
            serviceFqdn = "{{ .Values.onos.serviceFqdn }}"
            apiServerFqdn = "{{ .Values.onos.apiServerFqdn }}"
            apiServer = "{{ .Values.onos.apiServer }}"
            networkMode = "{{ .Values.onos.networkMode }}"
            dataCenter = "{{ .Values.meo.datacenter_id }}"
            cluster = "{{ .Values.meo.cluster_id }}"

            controller_ip = os.environ['MY_POD_IP']

            api_configs = {
                "scheme": scheme,
                "ipAddress": apiServer,
                "port": int(port),
                "caCertData": ca_cert_data,
                "clientCertData": client_cert_data,
                "clientKeyData": client_key_data,
                "serviceFqdn": serviceFqdn,
                "apiServerFqdn": apiServerFqdn,
                "controllerIp": controller_ip,
                "networkMode": networkMode,
                "datacenterId": dataCenter,
                "clusterId": cluster
            }
            data = {
                "apiConfigs": [
                    api_configs
                ]
            }
        except yaml.YAMLError as exc:
            print(exc)

    with open(outputfile, "w") as jsonfile:
        json.dump(api_configs, jsonfile)

if __name__ == "__main__":
    main(sys.argv[1:])
