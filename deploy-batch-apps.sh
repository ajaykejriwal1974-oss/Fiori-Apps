#!/usr/bin/env bash
# Deploy the apps corrected on 2026-08-30.
#
#   bash deploy-batch-apps.sh --test              # dry run, uploads NOTHING
#   bash deploy-batch-apps.sh                     # deploy all four
#   bash deploy-batch-apps.sh wip-batch-close     # deploy just one
#   bash deploy-batch-apps.sh wip-batch-close --test
#
# The `npm install` in the loop is not optional. Running `npx ui5 build` in an
# app folder whose node_modules is missing makes npx go looking for a package
# called "ui5" on the public registry, which does not exist - the UI5 CLI ships
# as @ui5/cli and is a devDependency here. That is the E404 you get if you run
# the build by hand in a fresh clone.
#
# CREDENTIALS: fiori deploy prompts once per app. Type them into that prompt.
# Do not commit a .env holding an SAP password - this repo is public.
#
# PACKAGE / TRANSPORT: each ui5-deploy.yaml names ZKGPL_FIORI and KSDK906759.
# The configs used to say $TMP, which was simply wrong - TADIR has always had
# these BSPs in ZKGPL_FIORI - and because that package is transportable the
# upload was refused for want of a transport request.
set -uo pipefail
cd "$(dirname "$0")"

ALL=(batch-status batch-status-fe contract-batch-update wip-batch-close)

MODE=""
APPS=()
for arg in "$@"; do
  case "$arg" in
    --test) MODE="--testMode"; echo ">>> TEST MODE - builds and validates, no upload" ;;
    *)      APPS+=("$arg") ;;
  esac
done
if [[ ${#APPS[@]} -eq 0 ]]; then APPS=("${ALL[@]}"); fi

for a in "${APPS[@]}"; do
  if [[ ! -d "apps/$a" ]]; then
    echo "No such app: $a"; echo "Known apps: ${ALL[*]}"; exit 1
  fi
done

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
