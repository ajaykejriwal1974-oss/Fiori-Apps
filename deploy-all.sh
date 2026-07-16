#!/bin/bash
# Deploy all 12 KGPL freestyle UI5 apps to KSD (client 500, package ZKGPL_FIORI,
# transport KSDK906624). Each app's target is in its ui5-deploy.yaml.
#
#   ./deploy-all.sh --test    # dry run: ABAP validates, uploads NOTHING
#   ./deploy-all.sh           # real deploy
#
# You are prompted ONCE for your SAP credentials. They are held only in this
# shell's environment for the run and never written to disk.
set -uo pipefail
cd "$(dirname "$0")"

APPS=(batch-status contract-batch-update dispatch-correction dyeing-packing \
      hu-unpack inbound-delivery-hus manage-packing-details mtos-process \
      palletization post-goods-movement-hu post-packing-gr \
      record-inspection-results-mass)

MODE=""
if [[ "${1:-}" == "--test" ]]; then MODE="--testMode"; echo ">>> TEST MODE — no actual upload"; fi

read -rp  "SAP username (KSD client 500): " SAP_DEPLOY_USER
read -rsp "SAP password: " SAP_DEPLOY_PASS; echo
export SAP_DEPLOY_USER SAP_DEPLOY_PASS

ok=0; fail=0; failed=""
for a in "${APPS[@]}"; do
  echo "==================== $a ===================="
  if ( cd "apps/$a" \
        && npx ui5 build --clean-dest >/dev/null 2>&1 \
        && npx fiori deploy --config ui5-deploy.yaml \
             --username SAP_DEPLOY_USER --password SAP_DEPLOY_PASS --yes $MODE ); then
     echo "OK   $a"; ok=$((ok+1))
  else
     echo "FAIL $a"; fail=$((fail+1)); failed="$failed $a"
  fi
done

unset SAP_DEPLOY_PASS
echo "======================================================"
echo "Deployed OK: $ok/12   Failed:${failed:- none}"
[[ -n "$failed" ]] && echo "Re-run for the failed ones after fixing, e.g.: (cd apps/<name> && npm run deploy)"
