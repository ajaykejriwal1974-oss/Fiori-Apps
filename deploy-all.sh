#!/usr/bin/env bash
# Deploy the 12 KGPL freestyle UI5 transactional apps to KSD (client 500,
# package ZKGPL_FIORI, transport KSDK906624). Each app's target lives in its
# ui5-deploy.yaml.
#
#   ./deploy-all.sh --test    # dry run: builds + validates, uploads NOTHING
#   ./deploy-all.sh           # real deploy
#
# You are prompted ONCE for your SAP credentials. They are held only in this
# shell's environment (UI5_TASK_ABAP_USER / _PASSWORD — the vars fiori deploy
# reads) for the run and never written to disk.
set -uo pipefail
cd "$(dirname "$0")"

APPS=(batch-status contract-batch-update dispatch-correction dyeing-packing \
      hu-unpack inbound-delivery-hus manage-packing-details mtos-process \
      palletization post-goods-movement-hu post-packing-gr \
      record-inspection-results-mass)

MODE=""
if [[ "${1:-}" == "--test" ]]; then MODE="--testMode"; echo ">>> TEST MODE — builds only, no upload"; fi

read -rp  "SAP username (KSD client 500): " SAP_U
read -rsp "SAP password:                  " SAP_P; echo
export UI5_TASK_ABAP_USER="$SAP_U"
export UI5_TASK_ABAP_PASSWORD="$SAP_P"

ok=0; fail=0; failed=""
for a in "${APPS[@]}"; do
  echo "==================== $a ===================="
  if ( cd "apps/$a" \
        && npm install --no-audit --no-fund --loglevel=error >/dev/null 2>&1 \
        && npx ui5 build --clean-dest >/dev/null 2>&1 \
        && npx fiori deploy --config ui5-deploy.yaml --yes $MODE ); then
     echo "OK   $a"; ok=$((ok+1))
  else
     echo "FAIL $a"; fail=$((fail+1)); failed="$failed $a"
  fi
done

unset UI5_TASK_ABAP_PASSWORD UI5_TASK_ABAP_USER SAP_P
echo "======================================================"
echo "Deployed OK: $ok/${#APPS[@]}   Failed:${failed:- none}"
[[ -n "$failed" ]] && echo "Re-run for the failed ones, e.g.: (cd apps/<name> && npx fiori deploy --config ui5-deploy.yaml --yes)"
exit 0
