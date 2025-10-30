# global-catalogsource.yaml

The `global-catalogsource.yaml` file is a Kubernetes manifest used to define a CatalogSource resource in OpenShift. This resource is part of the Operator Lifecycle Manager (OLM) and is used to specify the source of operator catalogs. The CatalogSource provides metadata about available operators and their versions, enabling users to install and manage operators within their OpenShift cluster.

## Bundles Image Lists

* public.ecr.aws/dedalus-ea/okd4/origin-cluster-logging-operator-bundle:5.9.0
* public.ecr.aws/dedalus-ea/okd4/elasticsearch-operator-bundle:5.8.0

The above images are built starting from the following repositories:

* https://github.com/dedalus-enterprise-architect/cluster-logging-operator
* https://github.com/dedalus-enterprise-architect/elasticsearch-operator

## Key Components

- **apiVersion**: Specifies the API version, typically `operators.coreos.com/v1alpha1`.
- **kind**: Defines the resource type, which is `CatalogSource`.
- **metadata**: Contains metadata about the resource, such as `name` and `namespace`.
- **spec**: Defines the specification for the CatalogSource, including:
    - **sourceType**: The type of source, usually `grpc`.
    - **image**: The container image that contains the operator catalog.
    - **displayName**: A human-readable name for the catalog.
    - **publisher**: The entity that publishes the catalog.

## Example

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
    name: global-catalog
    namespace: openshift-marketplace
spec:
    sourceType: grpc
    image: public.ecr.aws/example/global-catalog:latest
    displayName: Global Operator Catalog
    publisher: Example Publisher
```

This example defines a CatalogSource named `global-catalog` in the `openshift-marketplace` namespace, using a container image from Quay.io.

## Usage

To deploy the `global-catalogsource.yaml` file, use the following command:

```sh
oc apply -f global-catalogsource.yaml
```

This command will create the CatalogSource resource in your OpenShift cluster, making the specified operator catalog available for use.