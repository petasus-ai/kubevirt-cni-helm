# kubevirt-cni
Kubevirt-CNI is a kubevirt tailored CNI aims to provide VM friendly networking model. This CNI is recommended to be used only for kubevirt use case as a secondary interface with the help of multus-cni.

## TL;DR;

```console
$ git clone https://github.com/sonaproject/kubevirt-cni-helm.git
$ helm install kubevirt-cni kubevirt-cni-helm
```

## Introduction

This chart bootstraps a [kubevirt-cni](https://github.com/opennetworkinglab/onos/tree/master/apps/kubevirt-networking) deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Kubernetes 1.17+
- Kubevirt 0.36+
- OpenvSwitch 2.10+
- Helm 2.12+ or Helm 3.0-beta3+

## Installing the Chart

To install the chart with the release name `kubevirt-cni`:

```console
$ helm install kubevirt-cni kubevirt-cni-helm
```

These commands deploy kubevirt-cni on the Kubernetes cluster in the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `kubevirt-cni` deployment:

```console
$ helm delete kubevirt-cni
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Parameters

The following tables lists the configurable parameters of the SONA chart and their default values.
| Parameter                            | Description                                                            | Default                                      |
|--------------------------------------|------------------------------------------------------------------------|----------------------------------------------|
| `images.tags.curl`                   | CURL container image path                                              | `opensona/os-client-docker`                  |
| `images.tags.python`                 | Python container image path                                            | `opensona/python-docker`                     |
| `images.tags.onos`                   | ONOS container image path                                              | `opensona/onos-sona-nightly-docker:kubevirt` |                                 |         
| `images.pullPolicy`                  | All container images pull policy                                       | `IfNotPresent`                               |
| `onos.replicaCount`                  | ONOS POD replica number                                                | `1`                                          |
| `onos.hostNetwork`                   | Default networking deployment model, this will use host IP as POD IP   | `true`                                       |
| `onos.config.allowExtraRules`        | Allows to set up the flow rules from external source                   | `false`                                      |
| `onos.port.openflow`                 | Port used for interacting with OVS using OpenFlow protocol             | `6653`                                       |
| `onos.port.ovsdb`                    | Port used for interacting with OVS using OVSDB protocol                | `6640`                                       |
| `onos.port.onosWeb`                  | Port used for accessing ONOS web GUI and REST API                      | `8181`                                       |
| `onos.port.onosSsh`                  | Port used for accessing ONOS CLI console                               | `8101`                                       |
| `onos.port.onosCluster`              | Port used for communicating among ONOS nodes of a cluster              | `9876`                                       |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```console
$ helm install kubevirt-cni \
  --set images.pullPolicy=Always kubevirt-cni-helm
```

The above command sets the default image pull policy from ```IfNotPresent``` to  ```Always```.

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```console
$ helm install kubevirt-cni -f values.yaml kubevirt-cni-helm
```

> **Tip**: You can use the default [values.yaml](values.yaml)

## Use kubevirt-cni to attach secondary network interface
Following instructions are for setting up more complex network topology with Kubevirt using kubevirt-cni. In this example, we will try to attach two network interfaces: 1) Calico based POD network (default), 2) OVS based provider network.

1. In order to attach the secondary interface, we need to define a network using ```NetworkAttachmentDefinition``` CRD.
```console
$ kubectl apply -f networks/ovs-conf-host-local-no-ipam-flat.yaml
```
```yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: ovs-br-int
  annotations:
    network-config: '{
      "networkId": "ovs-br-int",
      "name": "ovs-br-int",
      "type": "FLAT",
      "mtu": 1500,
      "cidr": "10.10.10.0/24",
      "gatewayIp": "10.10.10.1",
      "ipPool": {
        "start": "10.10.10.100",
        "end": "10.10.10.200"
      }
    }'
spec:
  config: '{
    "cniVersion": "0.3.1",
    "type": "ovs",
    "bridge": "br-int",
    "ipam": {}
  }'
```
In above example yaml, we defined a network called ```ovs-br-int```, and specified network parameters like ```mtu```, ```cidr```, ```gatewayIp```, ```ipPool```. In order to communicate with the VM directly from out cluster without L3 router, we defined the network type as ```FLAT```, so that VM will get assigned a provider network IP address. Note that all VMs will get assigned the IP address from kubevirt-cni directly.

2. Add a ```physnet-config``` annotation to all worker node. Since in above example, we define the network as ```FLAT```, therefore, we need to tell kubevirt-cni with which uplink port that all VM traffic should be transferred. Assume that we have secondary physical interface ```eth1``` attached at host machine, and we use this interface as the uplink port for processing ```FLAT``` typed network traffic.
```console
$ ifconfig
...
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.2.1.35  netmask 255.255.255.0  broadcast 10.2.1.255
        inet6 fe80::f816:3eff:fe2b:945e  prefixlen 64  scopeid 0x20<link>
        ether fa:16:3e:2b:94:5e  txqueuelen 1000  (Ethernet)
        RX packets 53817568  bytes 9884189944 (9.2 GiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 57495640  bytes 40249139871 (37.4 GiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.1.1.10  netmask 255.255.255.0  broadcast 10.1.1.255
        inet6 fe80::f816:3eff:fe3d:8dce  prefixlen 64  scopeid 0x20<link>
        ether fa:16:3e:3d:8d:ce  txqueuelen 1000  (Ethernet)
        RX packets 1092192  bytes 431921913 (411.9 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 505288  bytes 113069659 (107.8 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
...
```
Following is the way to annotate this information, and tell kubevirt-cni to use ```eth1``` as the uplink port for ```physnet``` physical network.
```console
$ kubectl annotate nodes kubevirt-worker-1 physnet-config='[{ network: "physnet", interface: "eth1" }]'
$ kubectl annotate nodes kubevirt-worker-2 physnet-config='[{ network: "physnet", interface: "eth1" }]'
...
```

3. Install kubevirt-cni helm chart.
```console
$ git clone https://github.com/sonaproject/kubevirt-cni-helm.git
$ helm install kubevirt-cni kubevirt-cni-helm
```
Wait until all kubevirt-cni PODs are up and running.
```console
$ kubectl get po
NAME                                READY   STATUS     RESTARTS   AGE
sona-config-6458c4c448-9mnds        1/1     Running    0          171m
sona-onos-0                         1/1     Running    0          171m
```

4. Acccess kubevirt-cni console to check whether all configuraitons are in place.
```console
$ ssh -p 8101 karaf@localhost
Password authentication
Password:
Welcome to Open Network Operating System (ONOS)!
     ____  _  ______  ____
    / __ \/ |/ / __ \/ __/
   / /_/ /    / /_/ /\ \
   \____/_/|_/\____/___/

Documentation: wiki.onosproject.org
Tutorials:     tutorials.onosproject.org
Mailing lists: lists.onosproject.org

Come help out! Find out how at: contribute.onosproject.org

Hit '<tab>' for a list of available commands
and '[cmd] --help' for help on a specific command.
Hit '<ctrl-d>' or type 'logout' to exit ONOS session.

karaf@root > kubevirt-nodes
Hostname                           Type           Management IP            Data IP                  State
kubevirt-worker-1                  WORKER         10.2.1.39                10.2.1.39                COMPLETE
kubevirt-worker-2                  WORKER         10.2.1.13                10.2.1.13                COMPLETE

karaf@root > kubevirt-networks
ID                            Name                          Type           SegId     Gateway
ovs-br-int                    ovs-br-int                    FLAT           N/A       10.10.10.1
```

5. Spawn a VM with two network interfaces attached.
```console
$ kubectl apply -f vm-examples/vm-multus-centos-dhcp.yaml
```
```yaml
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  name: testvm-centos
spec:
  running: true
  template:
    metadata:
      labels:
        kubevirt.io/size: small
        kubevirt.io/domain: testvm-centos
    spec:
      terminationGracePeriodSeconds: 30
      domain:
        devices:
          disks:
            - name: containerdisk
              disk:
                bus: virtio
            - name: cloudinitdisk
              disk:
                bus: virtio
            - name: emptydisk
              disk:
                bus: virtio
          interfaces:
            - name: default
              bridge: {}
            - name: ovs-br-int-net
              bridge: {}
        resources:
          requests:
            memory: 1024M
      networks:
        - name: default
          pod: {}
        - multus:
            networkName: ovs-br-int
          name: ovs-br-int-net
      volumes:
        - name: containerdisk
          containerDisk:
            image: opensona/centos7-cloud-container-disk:latest
        - name: emptydisk
          emptyDisk:
            capacity: "2Gi"
        - name: cloudinitdisk
          cloudInitNoCloud:
            userData: |-
              #cloud-config
              password: centos
              ssh_pwauth: True
              chpasswd: { expire: False }
            networkData: |
              version: 2
              ethernets:
                eth0:
                  dhcp4: true
                eth1:
                  dhcp4: true
```

6. Check the connectivity to the VM via the secondary network interface.
```console
$ ping 10.10.10.100
PING 10.10.10.100 (10.10.10.100) 56(84) bytes of data.
64 bytes from 10.10.10.100: icmp_seq=1 ttl=64 time=1.87 ms
64 bytes from 10.10.10.100: icmp_seq=2 ttl=64 time=0.630 ms
64 bytes from 10.10.10.100: icmp_seq=3 ttl=64 time=0.791 ms
64 bytes from 10.10.10.100: icmp_seq=4 ttl=64 time=0.697 ms
```
