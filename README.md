# OpenShift Logging (EFK Stack)

Deploy Elasticsearch, Fluentd, and Kibana on OpenShift 4.14/4.15.

## Prerequisites

- OpenShift/OKD 4.14-4.18
- `oc` CLI with cluster-admin access
- [Dedalus Operators catalog](https://github.com/dedalus-enterprise-architect/dedalus-operators-catalog) configured
- Local clone of the repo

## Repository Contents

| File | Description |
|------|-------------|
| `manifests/operators/cluster-logging-operator.yml` | Namespace, OperatorGroup, Subscription for Cluster Logging |
| `manifests/operators/elasticsearch-operator.yml` | Subscription for Elasticsearch |
| `manifests/logging/clusterlogging.template.yml` | OpenShift template for ClusterLogging CR |
| `manifests/logging/clusterlogforwarder.yml` | ClusterLogForwarder CR |
| `manifests/logging/infra-node-placement.patch.yml` | Patch to schedule logging on infra nodes |
| `manifests/logging/params/single-node.example.params` | Parameters for single-node ES |
| `manifests/logging/params/multi-node.example.params` | Parameters for multi-node (3 nodes) |
| `manifests/logging/params/README.md` | Parameter documentation and usage |
| `manifests/kibana/kibana-externallink.template.yml` | Kibana link in OpenShift console |
| `manifests/elasticsearch/index_explicit_mapping_template.sh` | Script to apply custom index template |
| `manifests/elasticsearch/dedalus_template.json` | Custom Elasticsearch index template definition |

## Deployment

### 1. Install Elasticsearch operator
```bash
oc apply -f manifests/operators/elasticsearch-operator.yml
```
Check:
```bash
oc get subscription -n openshift-logging
```

### 2. Install Cluster Logging operator
```bash
oc apply -f manifests/operators/cluster-logging-operator.yml
```
Check:
```bash
oc get subscription -n openshift-logging
```

### 3. Deploy ClusterLogging instance

Ex. Single-node (1 ES node, zero redundancy):
```bash
oc process -f manifests/logging/clusterlogging.template.yml \
  --param-file=manifests/logging/params/single-node.example.params \
  | oc apply -n openshift-logging -f -
```

### 4. Deploy ClusterLogForwarder
```bash
oc apply -f manifests/logging/clusterlogforwarder.yml
```

### 5. Add Kibana link to OpenShift console
```bash
oc process -f manifests/kibana/kibana-externallink.template.yml \
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
oc patch ClusterLogging instance -n openshift-logging --type=merge --patch-file=manifests/logging/infra-node-placement.patch.yml
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
oc delete -f manifests/operators/cluster-logging-operator.yml
oc delete -f manifests/operators/elasticsearch-operator.yml
```