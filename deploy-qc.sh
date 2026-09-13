#!/usr/bin/env bash
# Deploy the three QC gate apps to KSD (client 500), transport KSDK906754.
#
#   bash deploy-qc.sh --test    # dry run: builds + validates, uploads NOTHING
#   bash deploy-qc.sh           # real deploy
#
# CREDENTIALS: fiori deploy prompts for them itself, once per app. An earlier
# version of this script exported UI5_TASK_ABAP_USER / _PASSWORD; the
# @sap/ux-ui5-tooling deploy task does not read those names and fell through to
# a 401 before prompting anyway. Rather than guess at variable names, this
# script lets the tool ask. To stop re-typing, the tooling reads a .env file -
# the exact variable names are in the URL the tool prints on the auth warning.
# Do not commit a .env containing a password.
#
# TRANSPORT: pinned to KSDK906759 in each ui5-deploy.yaml. Same rule as before -
# the request must be the one holding the matching backend change, because
# whichever half lands in KSQ first breaks the other. This time that is the
# Batch / Supplier Lot value helps: ZI_VH_QC_BATCH, ZI_VH_QC_SUPPLIER_LOT and
# the two expose lines in ZUI_QC_INSPECTION. Deploy the apps without them and
# the F4 dialogs call an entity set that is not there.
#
# KSDK906754, which these apps last went out on, was released on 2026-08-29 and
# cannot be reused. KSDK906760 is a task under KSDK906759, not a second request,
# so releasing KSDK906759 carries everything.
#
# See backend/qc-gate/NEXT-STEPS.md and CHANGE-2026-08-28-lotno.md
set -uo pipefail
cd "$(dirname "$0")"

APPS=(qc-raw-material qc-post-dyeing qc-post-winding)

MODE=""
if [[ "${1:-}" == "--test" ]]; then MODE="--testMode"; echo ">>> TEST MODE - builds and validates, no upload"; fi

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

echo
echo "==================== summary ===================="
echo "deployed: $ok    failed: $fail"
[[ -n "$failed" ]] && echo "failed apps:$failed"
exit $(( fail > 0 ))
