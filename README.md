# OpenShift Logging (EFK custom stack)

RedHat has announced the deprecation of the logging stack based on Elasticsearch, Fluentd, and Kibana on OpenShift using their operators
 - RedHat Cluster Logging Operator
 - RedHat ElasticSearch Operator
so this project allows to keep deploying the stack (wherever needed) using forked versions of those operators and a custom operator catalog.

## Prerequisites

- OpenShift/OKD 4.14-4.18
- `oc` CLI with cluster-admin access
- [Dedalus Operators catalog](https://github.com/dedalus-enterprise-architect/dedalus-operators-catalog) configured
- Local clone of the repo

## Repository Contents

| File | Description |
|------|-------------|
| `manifests/operators/cluster-logging-operator.yaml` | Namespace, OperatorGroup, Subscription for Cluster Logging |
| `manifests/operators/elasticsearch-operator.yaml` | Subscription for Elasticsearch |
| `manifests/logging/clusterlogging.template.yaml` | OpenShift template for ClusterLogging CR |
| `manifests/logging/clusterlogforwarder.yaml` | ClusterLogForwarder CR |
| `manifests/logging/infra-node-placement.patch.yaml` | Patch to schedule logging on infra nodes |
| `manifests/logging/params/single-node.example.params` | Parameters for single-node ES |
| `manifests/logging/params/multi-node.example.params` | Parameters for multi-node (3 nodes) |
| `manifests/logging/params/README.md` | Parameter documentation and usage |
| `manifests/kibana/kibana-externallink.template.yaml` | Kibana link in OpenShift console |
| `manifests/elasticsearch/index_explicit_mapping_template.sh` | Script to apply custom index template |
| `manifests/elasticsearch/dedalus_template.json` | Custom Elasticsearch index template definition |

## Deployment

### 1. Install Elasticsearch operator
```bash
oc apply -f manifests/operators/elasticsearch-operator.yaml
```
Check:
```bash
oc get subscription -n openshift-operators-redhat
```

### 2. Install Cluster Logging operator
```bash
oc apply -f manifests/operators/cluster-logging-operator.yaml
```
Check:
```bash
oc get subscription -n openshift-logging
```

### 3. Deploy ClusterLogging instance

Ex. Single-node (1 ES node, zero redundancy):
```bash
oc process -f manifests/logging/clusterlogging.template.yaml \
  --param-file=manifests/logging/params/single-node.example.params \
  | oc apply -n openshift-logging -f -
```

### 4. Deploy ClusterLogForwarder
```bash
oc apply -f manifests/logging/clusterlogforwarder.yaml
```

### 5. Add Kibana link to OpenShift console
```bash
oc process -f manifests/kibana/kibana-externallink.template.yaml \
  -p KIBANA_ROUTE=$(oc get route kibana -n openshift-logging -o jsonpath='{.spec.host}') \
  | oc apply -n openshift-logging -f -
```

### 6. Apply custom Elasticsearch index template
```bash
. manifests/elasticsearch/index_explicit_mapping_template.sh
```
Expected output: `{"acknowledged":true}`

### 7. (Optional) Configure infra node placement
Schedule Elasticsearch and Kibana on infrastructure nodes:
```bash
oc patch ClusterLogging instance -n openshift-logging --type=merge --patch-file=manifests/logging/infra-node-placement.patch.yaml
```
See `manifests/logging/README.md` for prerequisites.

## Elasticsearch Commands

Get an Elasticsearch pod:
```bash
es_pod=$(oc get pods -l component=elasticsearch -n openshift-logging --no-headers | head -1 | awk '{print $1}')
```

Get index template:
```bash
oc exec -n openshift-logging -c elasticsearch $es_pod -- es_util --query=_template/dedalus_es_template
```

Delete index template:
```bash
oc exec -n openshift-logging -c elasticsearch $es_pod -- es_util --query=_template/dedalus_es_template -XDELETE
```

List all templates:
```bash
oc exec -n openshift-logging -c elasticsearch $es_pod -- es_util --query=_template | jq
```

## Troubleshooting

Check pod status:
```bash
oc get pods -n openshift-logging
```

Check operator subscriptions:
```bash
oc get subscription -n openshift-logging
```

Check ClusterLogging status:
```bash
oc get ClusterLogging instance -n openshift-logging -o yaml
```

Check all logging components by label:
```bash
oc get all -l app=dedalus-logging -n openshift-logging
```

## Uninstall

```bash
oc delete ClusterLogForwarder instance -n openshift-logging
oc delete ClusterLogging instance -n openshift-logging
oc delete -f manifests/operators/cluster-logging-operator.yaml
oc delete -f manifests/operators/elasticsearch-operator.yaml
```

**Note:** Deleting the ClusterLogging and Elasticsearch resources does not automatically remove persistent volumes (PVs) or persistent volume claims (PVCs) created for Elasticsearch storage. To fully clean up storage resources, manually delete any related PVCs and PVs:

```bash
oc get pvc -n openshift-logging
oc delete pvc <pvc-name> -n openshift-logging
```
Repeat for all Elasticsearch-related PVCs as needed. This ensures no orphaned storage remains after uninstall.
```