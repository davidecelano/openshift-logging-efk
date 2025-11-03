#!/usr/bin/env bash
set -euo pipefail

es_pod=$(oc -n openshift-logging get pods -l component=elasticsearch --no-headers | head -1 | awk '{print $1}')

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_JSON="$SCRIPT_DIR/dedalus_es_template.json"

if [[ ! -f "$TEMPLATE_JSON" ]]; then
  echo "Template JSON not found: $TEMPLATE_JSON" >&2
  exit 1
fi

oc exec -n openshift-logging -c elasticsearch "$es_pod" -- es_util --query=_template/dedalus_es_template -XPUT -d@"$TEMPLATE_JSON"
