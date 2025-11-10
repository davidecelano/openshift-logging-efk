# ClusterLogging Manifests

ClusterLogging instance template and forwarder configuration.

## Files

- `clusterlogging.template.yaml` - OpenShift template for ClusterLogging CR
- `clusterlogforwarder.yaml` - ClusterLogForwarder CR for log routing
- `infra-node-placement.patch.yaml` - Patch to schedule logging components on infra nodes
- `params/` - Parameter files for different deployment profiles

## Infra Node Placement

The `infra-node-placement.patch.yaml` file configures the ClusterLogging instance to:
- Schedule Elasticsearch and Kibana pods on infrastructure nodes using `nodeSelector`
- Allow Fluentd collectors to run on all nodes (including master and infra) via tolerations

### Usage

After deploying the ClusterLogging instance, apply the patch:

```bash
oc patch ClusterLogging instance -n openshift-logging --type=merge --patch-file=infra-node-placement.patch.yaml
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
