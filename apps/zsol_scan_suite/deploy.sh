#!/bin/bash
# ---------------------------------------------------------------------------
# KGPL Scan Suite - front-end deploy to KSD (BSP ZSOL_SCAN_SUITE, client 500)
#
# HOW TO RUN (in Terminal):
#     cd ~/Desktop/Fiori-Apps/apps/zsol_scan_suite
#     bash deploy.sh
#
# You will be asked for your SAP password at the Fiori prompt. It is typed
# straight into the SAP tooling and is never saved anywhere by this script.
# ---------------------------------------------------------------------------
set -e

# Always work from the folder this script lives in (the app folder), so it
# does not matter which directory you started Terminal in.
cd "$(dirname "$0")"
echo "Deploying from: $(pwd)"
echo ""

# 1. Tools present?
command -v node >/dev/null 2>&1 || { echo "ERROR: node (Node.js) not found - install it first."; exit 1; }
command -v npm  >/dev/null 2>&1 || { echo "ERROR: npm not found."; exit 1; }

# 2. Required files present?
for f in index.html ui5-deploy.yaml package.json; do
  [ -f "$f" ] || { echo "ERROR: $f not found in this folder - are you in apps/zsol_scan_suite?"; exit 1; }
done

# 3. Verify the app's JavaScript parses BEFORE uploading anything.
node -e '
  const fs = require("fs");
  const html = fs.readFileSync("index.html", "utf8");
  const js = [...html.matchAll(/<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/g)]
               .map(m => m[1]).join("\n;\n");
  new Function(js);              // throws on a syntax error, does not run the code
  console.log("index.html JavaScript: OK");
'

# 4. Show the transport it will upload into, and ask before proceeding.
TR=$(grep -E "^[[:space:]]*transport:" ui5-deploy.yaml | head -1 | sed "s/.*transport:[[:space:]]*//" | tr -d "\r")
echo ""
echo "  Target system : KSD, client 500"
echo "  Target BSP    : ZSOL_SCAN_SUITE"
echo "  Transport     : ${TR:-<not found in ui5-deploy.yaml>}"
echo ""
printf "Proceed with deploy? [y/N] "
read ans
case "$ans" in
  y|Y|yes|YES) ;;
  *) echo "Cancelled - nothing was uploaded."; exit 0 ;;
esac

# 5. Deploy. The Fiori tooling prompts for your SAP password here.
echo ""
echo "Starting deploy - enter your SAP password when the tool asks for it..."
npm run deploy

echo ""
echo "Done. Now open the app and hard-refresh (Cmd-Shift-R):"
echo "  http://192.168.0.19:8000/sap/bc/ui5_ui5/sap/zsol_scan_suite/index.html?sap-client=500"
