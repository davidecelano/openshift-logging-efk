# ClusterLogging Parameters

Parameter files for deploying ClusterLogging instances with different sample configurations.

## Files

- `single-node.example.params` - Single-node Elasticsearch deployment
- `multi-node.example.params` - Multi-node (HA) Elasticsearch deployment (3 nodes)

## Parameters

| Parameter | Description | Single Node | Multi-node |
|-----------|-------------|-------------|-----------|
| ES_NODE_COUNT | Number of Elasticsearch nodes | 1 | 3 |
| ES_MEMORY | Memory per ES node | 4Gi | 8Gi |
| PROXY_MEMORY | ES proxy memory | 256Mi | 256Mi |
| REDUNDANCY_POLICY | Shard redundancy policy | ZeroRedundancy | SingleRedundancy |
| STORAGE_SIZE | PV size per node | 50G | 50G |
| STORAGECLASS | Storage class name | (required) | (required) |
| KIBANA_REPLICAS | Kibana pod replicas | 1 | 2 |
| RETENTION_APP | Application log retention | 7d | 7d |
| RETENTION_AUDIT | Audit log retention | 2d | 2d |
| RETENTION_INFRA | Infrastructure log retention | 2d | 2d |

## Redundancy Policies

| Policy | Description | Min Nodes |
|--------|-------------|-----------|
| ZeroRedundancy | No replicas, data loss if node fails | 1 |
| SingleRedundancy | 1 replica per shard | 2 |
| MultipleRedundancy | Replicas on half the nodes | 3+ |
| FullRedundancy | Replicas on all nodes | 2+ |

## Usage

Use with `oc process`:

```bash
oc process -f ../clusterlogging.template.yaml \
  --param-file=single-node.example.params \
  | oc apply -f -
```
