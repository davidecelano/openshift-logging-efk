# OpenShift Logging Resources

This project collects some procedures on how to set up a custom EFK instance based on the following minimum requirements:

* __Dedalus__ OpenShift Cluster Logging Operator - version 5.9.x
* __RedHat__ ElasticSearch Operator - version 5.8.x
* _OpenShift_ / _OKD_ version: 4.14, 4.15, 4.16 (not tested yet: 4.17, 4.18)

References:

* <https://github.com/dedalus-enterprise-architect/openshift-logging-efk/blob/feature/v5.9.0-dedalus/README.md>
* <https://github.com/openshift/elasticsearch-operator>

## OpenShift Cluster Logging: Overview

This project focuses on the following topics:

* logging persistent storage
* custom indexes template to avoid field map explosion
* improving index retention
* Kibana custom structured field view

Explore the files used by this project:

* `deploy/catalogsource/global-catalogsource.yaml`: Dedalus __CatalogSource__ definition
* `deploy/clusterlogging/cl-forwarder.yml`: __cluster forwarder instance__ definition
* `deploy/clusterlogging/cl-instance.template.yml`: __cluster logging instance__ definition for a single pod deployment
* `deploy/clusterlogging/cl-instance-ha.template.yml`: __cluster logging instance__ definition for a high-availability deployment; _tolerations_ directives have been implemented for Infra node roles, uncomment them when needed
* `deploy/clusterlogging/cl-operator.yml`: template to install the Dedalus Openshift Cluster Logging Operator stack
* `deploy/elasticsearch/es-operator.yml`: template to install the RedHat ElasticSearch Operator
* `deploy/elasticsearch/index_explicit_mapping_template.sh`: script to create a custom index template on ElasticSearch
* `deploy/kibana/kibana-externallink.template.yml`: template to create a Route to publish Kibana link aimed to have a custom fields view available as default

### Project minimum requirements

* The OpenShift client utility: `oc`
* Cluster admin role rights
* __Dedalus Operators__ catalog available on the cluster. No pull secret is required!
* Local clone of the Git project

### Import the CatalogSource of Dedalus

Before go on you need to configure the Dedalus _CatalogSource_ object as follow:

```bash
oc apply -f deploy/catalogsource/global-catalogsource.yaml
```

### RedHat ElasticSearch Operator: setup

> WARNING: an Admin Cluster Role is required to proceed in this section.

Run the following command to install the RedHat ElasticSearch Operator:

```bash
oc apply -f deploy/elasticsearch/es-operator.yml
```

> Check objects

Get a list of the objects created:

```bash
oc get all,ConfigMap,Secret,Elasticsearch,OperatorGroup,Subscription -l app=es-logging-dedalus --no-headers -n openshift-operators-redhat | cut -d' ' -f1
```

### Dedalus OpenShift Cluster Logging Operator: setup

> WARNING: an Admin Cluster Role is required to proceed in this section.

Run the following command to install the Dedalus OpenShift Cluster Logging Operator:

1. Instantiate the _Cluster Logging Operator_:

```bash
oc apply -f deploy/clusterlogging/cl-operator.yml -n openshift-logging
```

2. Instantiate the _ClusterLogging_ instance with inline parameters:

```bash
oc process -f deploy/clusterlogging/cl-instance.template.yml \
   -p STORAGECLASS=@type_here_the_custom_storageclass@ \
   | oc -n openshift-logging apply -f -
```

3. Instantiate the _Cluster Forwarder_:

```bash
oc apply -f deploy/clusterlogging/cl-forwarder.yml -n openshift-logging
```

> Check objects

Get a list of the objects created:

```bash
oc get all,ConfigMap,Secret,OperatorGroup,Subscription,ClusterLogging,ClusterLogForwarder \
   -l app=cl-logging-dedalus --no-headers -n openshift-logging | cut -d' ' -f1
```

### Kibana: create the External Console Link

> WARNING: an Admin Cluster Role is required to proceed in this section.

Run the following command to create the External Console Link for Kibana default View:

```bash
oc process -f deploy/kibana/kibana-externallink.template.yml \
   -p KIBANA_ROUTE=$(oc get route kibana -n openshift-logging -o jsonpath='{.spec.host}') \
   | oc -n openshift-logging apply -f -
```

> Check objects

Get a list of the objects created:

```bash
oc get ConsoleExternalLogLink -l app=es-logging-dedalus --no-headers -n openshift-logging | cut -d' ' -f1
```

## ElasticSearch: create the index template

Create the default index template:

```bash
. deploy/elasticsearch/index_explicit_mapping_template.sh
```

If the command is successful, the output will be:

```json
{"acknowledged":true}
```

### Useful ElasticSearch commands

Getting the ES pod name as a prerequisite for the next commands:

```bash
es_pod=$(oc -n openshift-logging get pods -l component=elasticsearch -o jsonpath='{.items[0].metadata.name}')
```

* Getting all the rejected events from Pods:

```bash
oc logs -n openshift-logging ${es_pod} -c elasticsearch -f
```

* Getting a specific Template:

```bash
oc exec -n openshift-logging -c elasticsearch ${es_pod} -- es_util --query=_template/dedalus_es_template
```

* Delete Template:

```bash
oc exec -n openshift-logging -c elasticsearch ${es_pod} -- es_util --query=_template/dedalus_es_template -XDELETE
```

* Delete an Index Pattern by using the DevTools on Kibana UI: ```DELETE app-platform-dc4h-test-*```


* Getting All Templates:

```bash
oc exec -n openshift-logging -c elasticsearch ${es_pod} -- es_util --query=_template | jq "[.]"
```

If you have any other questions or need further details, feel free to ask! 😊