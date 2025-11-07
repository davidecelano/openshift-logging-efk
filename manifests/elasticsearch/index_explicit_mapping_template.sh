

#!/usr/bin/env bash
# Do not use 'set -euo pipefail' so the terminal does not exit after execution

# This script can be run from any directory. It always resolves the JSON template relative to its own location.

es_pod=$(oc -n openshift-logging get pods -l component=elasticsearch --no-headers | head -1 | awk '{print $1}')

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_JSON="$SCRIPT_DIR/dedalus_es_template.json"


if [[ ! -f "$TEMPLATE_JSON" ]]; then
  echo "Template JSON not found: $TEMPLATE_JSON" >&2
  echo "Script completed with warning: template not found."
  return 1 2>/dev/null || true
fi

cat "$TEMPLATE_JSON" | oc exec -i -n openshift-logging -c elasticsearch "$es_pod" -- es_util --query=_template/dedalus_es_template -XPUT -d@-
