# ClusterLogging Instance Parameters

This directory contains a unified template and parameter files for deploying ClusterLogging instances.

## Files

- `cl-instance.template.yml` - Parameterized OpenShift template
- `es-single-node.example.params` - Single-node deployment configuration
- `es-ha.example.params` - High-availability deployment configuration

## Parameters

| Parameter | Description | Single | HA |
|-----------|-------------|--------|-----|
| `ES_NODE_COUNT` | Number of Elasticsearch nodes | 1 | 3 |
| `ES_MEMORY` | Memory per ES node | 4Gi | 8Gi |
| `PROXY_MEMORY` | ES proxy memory | 256Mi | 256Mi |
| `REDUNDANCY_POLICY` | Shard redundancy | ZeroRedundancy | SingleRedundancy |
| `STORAGE_SIZE` | PV size per node | 50G | 50G |
| `STORAGECLASS` | Storage class name | (empty) | (empty) |
| `KIBANA_REPLICAS` | Kibana pod replicas | 1 | 2 |
| `RETENTION_APP` | Application log retention | 7d | 7d |
| `RETENTION_AUDIT` | Audit log retention | 2d | 2d |
| `RETENTION_INFRA` | Infrastructure log retention | 2d | 2d |

## Usage Examples

### Single-node deployment
```bash
oc process -f cl-instance.template.yml \
  --param-file=es-single-node.example.params \
  -p STORAGECLASS=my-storage-class \
  | oc -n openshift-logging apply -f -
```

### High-availability deployment
```bash
oc process -f cl-instance.template.yml \
  --param-file=es-ha.example.params \
  -p STORAGECLASS=my-storage-class \
  | oc -n openshift-logging apply -f -
```

### Custom configuration
```bash
oc process -f cl-instance.template.yml \
  --param-file=es-single-node.example.params \
  -p STORAGECLASS=my-storage-class \
  -p ES_NODE_COUNT=2 \
  -p ES_MEMORY=6Gi \
  -p RETENTION_APP=14d \
  | oc -n openshift-logging apply -f -
```

### Override all parameters via CLI
```bash
oc process -f cl-instance.template.yml \
  -p ES_NODE_COUNT=5 \
  -p ES_MEMORY=16Gi \
  -p PROXY_MEMORY=512Mi \
  -p REDUNDANCY_POLICY=MultipleRedundancy \
  -p STORAGE_SIZE=100G \
  -p STORAGECLASS=fast-ssd \
  -p KIBANA_REPLICAS=3 \
  -p RETENTION_APP=30d \
  -p RETENTION_AUDIT=7d \
  -p RETENTION_INFRA=7d \
  | oc -n openshift-logging apply -f -
```

## Redundancy Policies

- **ZeroRedundancy**: No replica shards (single node, data loss if node fails)
- **SingleRedundancy**: One replica per shard (minimum 2 nodes)
- **MultipleRedundancy**: Replicas on half the nodes
- **FullRedundancy**: Replicas on all nodes (maximum safety, highest resource usage)

## Notes

- The `STORAGECLASS` parameter must be set to an available StorageClass in your cluster
- Parameters can be edited in the `.env` files or overridden via `-p` flags
- The `--param-file` loads defaults, `-p` overrides can be added after
