# Build the Cluster Logging Operator: setup the environment

The Git Project of reference here is: https://github.com/dedalus-enterprise-architect/openshift-logging-efk

## Definitions

- **OperatorHub**: The web console interface in OpenShift Container Platform that cluster administrators use to discover and install Operators.

- **RedHat Elasticsearch Operator**

## Pre-Requisites for building the sources

- **oc client** (not kubectl) - references: OKD Releases

  ```bash
  curl -s -L https://github.com/okd-project/okd/releases/download/4.15.0-0.okd-2024-03-10-010116/openshift-client-linux-4.15.0-0.okd-2024-03-10-010116.tar.gz -O
  sudo tar xzvf openshift-client-linux-*.tar.gz -C /usr/local/bin --wildcards 'oc'
  ```

- **Golang v1.22.5**

  ```bash
  wget https://golang.org/dl/go1.22.5.linux-amd64.tar.gz
  sudo tar -C /usr/local -xzf go1.22.5.linux-amd64.tar.gz
  echo -e "export GO111MODULE=on\nexport GOPATH=\$HOME/go\nexport PATH=\$PATH:/usr/local/go/bin:\$GOPATH/bin" > ~/.go_setenv
  source ~/.go_setenv
  ```

  Add to `~/.bashrc`:

  ```bash
  if [ -f ~/.go_setenv ]; then
      . ~/.go_setenv
  fi
  ```

- **kubectl and oc (OpenShift CLI)**
- **make**
- **opm**:

  ```bash
  chmod +x linux-amd64-opm
  sudo mv linux-amd64-opm /usr/local/bin/opm
  opm version
  ```

  Output:

  ```plaintext
  Version: version.Version{OpmVersion:"v1.48.0", GitCommit:"dc238431", BuildDate:"2024-10-25T18:18:26Z", GoOs:"linux", GoArch:"amd64"}
  ```

- Create the AWS ECR public repository:
  - public.ecr.aws/dedalus-ea/okd4/elasticsearch-operator
  - public.ecr.aws/dedalus-ea/okd4/elasticsearch-operator-bundle
  - public.ecr.aws/dedalus-ea/okd4/elasticsearch-operator-index
  - public.ecr.aws/dedalus-ea/ubi9/go-toolset (registry.redhat.io/ubi9/go-toolset)
    See: Red Hat UBI9 Go Toolset

## Setup

Clone the following Git repository: `https://github.com/dedalus-enterprise-architect/cluster-logging-operator` as previously forked.

### Run the Checks

  Before proceeding, apply the following replacements:

- get the golang project dependecies:

  ```bash
  # bingo get
  make tools
  ```

### Pre-Requisites

- To upgrade operator-sdk:
  _WARNING_: Please refer to the matrix: Kubernetes Version Compatibility
  - Read the link at: Upgrading Operator SDK
  - Check the migration steps if any: Upgrading SDK Version

### Get and Re-Tag the Image

Get the original ES image:

```bash
podman pull quay.io/openshift-logging/elasticsearch-operator:5.8.0
podman tag quay.io/openshift-logging/elasticsearch-operator:5.8.0 public.ecr.aws/dedalus-ea/okd4/elasticsearch-operator:5.8.0
pod
```

### Build and push the Bundle image

```bash
podman build -t quay.io/openshift-logging/elasticsearch-operator-bundle:5.8.0 -f bundle.Dockerfile .
podman push public.ecr.aws/dedalus-ea/okd4/elasticsearch-operator-bundle:5.8.0
```

### Build the index image

This is aimed for multiple bundles image by a global index image.
The example below is refered to two images:

- Dedalus cluster logging operator
- RedHat elasticsearch operator

```bash
/opt/dedalus/cprato/go/bin/opm-v1.48.0 index add \
  --bundles public.ecr.aws/dedalus-ea/okd4/origin-cluster-logging-operator-bundle:5.9.0,public.ecr.aws/dedalus-ea/okd4/elasticsearch-operator-bundle:5.8.0 \
  --tag public.ecr.aws/dedalus-ea/okd4/operators-catalog-index:latest
```

The above commands create the following image:

```plaintext
==> Build: public.ecr.aws/dedalus-ea/okd4/origin-cluster-logging-operator-index
```

### Push the Index image

podman push public.ecr.aws/dedalus-ea/okd4/origin-cluster-logging-operator-index:latest
