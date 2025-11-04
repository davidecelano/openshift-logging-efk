# ClusterLogging Manifests

ClusterLogging instance template and forwarder configuration.

## Files

- `clusterlogging.template.yml` - OpenShift template for ClusterLogging CR
- `clusterlogforwarder.yml` - ClusterLogForwarder CR for log routing
- `infra-node-placement.patch.yml` - Patch to schedule logging components on infra nodes
- `params/` - Parameter files for different deployment profiles

## Infra Node Placement

The `infra-node-placement.patch.yml` file configures the ClusterLogging instance to:
- Schedule Elasticsearch and Kibana pods on infrastructure nodes using `nodeSelector`
- Allow Fluentd collectors to run on all nodes (including master and infra) via tolerations

### Usage

After deploying the ClusterLogging instance, apply the patch:

```bash
oc patch ClusterLogging instance -n openshift-logging --type=merge --patch-file=infra-node-placement.patch.yml
```

### Prerequisites

Ensure your infrastructure nodes are labeled:

```bash
oc label node <node-name> node-role.kubernetes.io/infra=""
```

And tainted (optional):

```bash
oc adm taint node <node-name> node-role.kubernetes.io/infra=:NoSchedule
```
