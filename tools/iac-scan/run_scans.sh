#!/usr/bin/env bash
# Run checkov and tfsec over terraform/ and regenerate the reconciled findings doc.
# Requires: checkov (pip install checkov), tfsec (https://github.com/aquasecurity/tfsec/releases).
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
out="${SCAN_OUT_DIR:-$root/.iac-scan}"
mkdir -p "$out"
checkov -d "$root/terraform" -o json --quiet --compact > "$out/checkov.json" || true
tfsec "$root/terraform" --format json --no-color --soft-fail > "$out/tfsec.json"
python3 "$root/tools/iac-scan/reconcile.py" "$out/checkov.json" "$out/tfsec.json" \
  > "$root/docs/security/iac-findings-reconciled.md"
echo "checkov $(checkov --version), tfsec $(tfsec --version 2>/dev/null | tail -1)"
