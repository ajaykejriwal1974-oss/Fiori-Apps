#!/usr/bin/env bash
# Deploy the 12 Fiori Elements master-data apps to KSD (client 500).
# SAP credentials are prompted ONCE and held only in the shell environment
# (UI5_TASK_ABAP_*) — never written to disk. Continues past a failed app.
set -uo pipefail
cd "$(dirname "$0")/apps"

APPS=(
  recipe-master job-master schedule-master merge-master
  checked-by-master packing-material-master transport-code-master
  export-detail-master gate-pass-master truck-master
  digital-signature-master cform-master
)

read -rp  "SAP user (KSD 500): " SAP_U
read -rsp "SAP password:      " SAP_P; echo
export UI5_TASK_ABAP_USER="$SAP_U"
export UI5_TASK_ABAP_PASSWORD="$SAP_P"

declare -a OK=() FAIL=()
for a in "${APPS[@]}"; do
  echo; echo "================ $a ================"
  if ( cd "$a" \
        && npm install --no-audit --no-fund >/dev/null 2>&1 \
        && npm run build >/dev/null 2>&1 \
        && npx fiori deploy --yes ); then
    echo ">> $a  OK"; OK+=("$a")
  else
    echo ">> $a  FAILED"; FAIL+=("$a")
  fi
done

unset UI5_TASK_ABAP_PASSWORD UI5_TASK_ABAP_USER
echo
echo "===================================================="
echo "Deployed OK (${#OK[@]}): ${OK[*]:-none}"
echo "Failed   (${#FAIL[@]}): ${FAIL[*]:-none}"
