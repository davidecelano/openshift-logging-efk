# OpenShift Logging Resources

This project collects some procedures on how to setup a custom EFK instance based on the following minimum requirements:

 * RedHat OpenShift Cluster Logging Operator - version 5.9.1

 * RedHat ElasticSearch Operator - version 5.8.6
 
 * OpenShift 4.14, 4.15

References:
  - https://github.com/openshift/cluster-logging-operator
  - https://github.com/openshift/elasticsearch-operator

## OpenShift Cluster Logging: Overview

This project focus on the following topics:

    * logging persistent storage
    * custom indexes template in order to avoiding the field's map explosion
    * improving the indexes retention
    * kibana custom structured field view

Explore the files used by this project:

* ```deploy/clusterlogging/cl-forwarder.yml``` : __cluster forwarder instance__ definition

* ```deploy/clusterlogging/cl-instance.template.yml``` : __cluster logging instance__ parameterized template

* ```deploy/clusterlogging/es-single-node.example.params``` : parameters for single-node deployment

* ```deploy/clusterlogging/es-ha.example.params``` : parameters for high-availability deployment

* ```deploy/clusterlogging/cl-operator.yml``` : template to install the RedHat Openshift Cluster Logging Operator stack

* ```deploy/elasticsearch/es-operator.yml``` : template to install the RedHat ElasticSearch Operator

* ```deploy/elasticsearch/index_explicit_mapping_template.sh``` : script to create a custom index template on ElasticSearch

* ```deploy/kibana/kibana-externallink.template.yml``` : template to create a Route to publish Kibana link aimed to have a custom fields view available as default

### Project minimum requirements

* The OpenShift client utility: ```oc```

* A cluster admin roles rights

* RedHat Operators catalog available on cluster

* Git project local clone

### RedHat ElasticSearch Operator: setup

> WARNING: an Admin Cluster Role is required to proceed on this section.

Run the following command to install the RedHat ElasticSearch Operator:

```
   oc apply -f deploy/elasticsearch/es-operator.yml
```

> Check objects

Get a list of the objects created:

```
   # All Elasticsearch operator resources
   oc get OperatorGroup,Subscription -l component=elasticsearch-operator -n openshift-logging
   
   # Or all operator resources
   oc get OperatorGroup,Subscription -l app=dedalus-logging -n openshift-logging
```

### RedHat OpenShift Cluster Logging Operator: setup

> WARNING: an Admin Cluster Role is required to proceed on this section.

Run the following command to install the RedHat OpenShift Cluster Logging Operator:

1. Instanciate the _Cluster Logging Operator_:

```
   oc apply -f deploy/clusterlogging/cl-operator.yml -n openshift-logging
```

2. Instanciate the _ClusterLogging_ instance with inline parameters:

**Single-node deployment:**
```
   oc process -f deploy/clusterlogging/cl-instance.template.yml \
     --param-file=deploy/clusterlogging/es-single-node.example.params \
     -p STORAGECLASS=@type_here_the_custom_storageclass@ \
     | oc -n openshift-logging apply -f -
```

**High-availability deployment:**
```
   oc process -f deploy/clusterlogging/cl-instance.template.yml \
     --param-file=deploy/clusterlogging/es-ha.example.params \
     -p STORAGECLASS=@type_here_the_custom_storageclass@ \
     | oc -n openshift-logging apply -f -
```

**Custom deployment (override individual parameters):**
```
   oc process -f deploy/clusterlogging/cl-instance.template.yml \
     --param-file=deploy/clusterlogging/es-single-node.example.params \
     -p STORAGECLASS=my-storage-class \
     -p ES_NODE_COUNT=2 \
     -p ES_MEMORY=6Gi \
     -p RETENTION_APP=14d \
     | oc -n openshift-logging apply -f -
```

3. Instanciate the _Cluster Forwarder_:

```
   oc apply -f deploy/clusterlogging/cl-forwarder.yml -n openshift-logging
```

> Check objects

Get a list of the objects created:

```
   # All logging instance resources
   oc get ClusterLogging,ClusterLogForwarder -l app=dedalus-logging -n openshift-logging
   
   # Instance only
   oc get ClusterLogging -l component=instance -n openshift-logging
   
   # Forwarder only
   oc get ClusterLogForwarder -l component=forwarder -n openshift-logging
```

### Kibana: create the External Console Link

> WARNING: an Admin Cluster Role is required to proceed on this section.

Run the following command to create the External Console Link for Kibana default View:

```
   oc process -f deploy/kibana/kibana-externallink.template.yml \
     -p KIBANA_ROUTE=$(oc get route kibana -n openshift-logging -o jsonpath='{.spec.host}') \
     | oc -n openshift-logging apply -f -
```

> Check objects

Get a list of the objects created:

```
   oc get ConsoleExternalLogLink -l component=console-link -n openshift-logging
```

## ElasticSearch: create the index template

Create the default index template:

```bash
   . deploy/elasticsearch/index_explicit_mapping_template.sh
```

If the command is successful, will be returned the output:

```json
   {"acknowledged":true}
```

### Useful ElasticSearch commands

Getting the ES pod name as pre-requirements for the nexts commands:

```bash
   es_pod=$(oc -n openshift-logging get pods -l component=elasticsearch --no-headers | head -1 | cut -d" " -f1)
```

* Getting a specific Template:

```bash
   oc exec -n openshift-logging -c elasticsearch ${es_pod} -- es_util --query=_template/dedalus_es_template
```

* Delete Template:

```bash
   oc exec -n openshift-logging -c elasticsearch ${es_pod} -- es_util --query=_template/dedalus_es_template -XDELETE
```

* Getting All Templates:

```bash
   oc exec -n openshift-logging -c elasticsearch ${es_pod} -- es_util --query=_template | jq "[.]"
```