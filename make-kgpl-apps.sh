#!/usr/bin/env bash
# Scaffolds 5 SAP Fiori Elements (V4 List Report) apps for the KGPL services built this session.
# Deploy each with:  cd <app> && npm install && npm run deploy
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"

# module | service uri | entity | BSP | semObj | action | icon | title | subtitle
APPS=(
"zpurchasereg|/sap/opu/odata4/sap/zui_purchase_register_04/srvd/sap/zui_purchase_register/0001/|PurchaseRegister|ZPURCHASEREG|PurchaseRegister|display|receipt|Purchase Register|GST purchase register"
"zpalletstock|/sap/opu/odata4/sap/zui_pallet_stock_04/srvd/sap/zui_pallet_stock/0001/|PalletStock|ZPALLETSTOCK|PalletStock|display|pallet|Pallet Stock|Stock at customer"
"zpackingunit|/sap/opu/odata4/sap/zui_packing_04/srvd/sap/zui_packing/0001/|PackingUnit|ZPACKINGUNIT|PackingUnit|display|shipping-status|Packing Units|Existing handling units"
"zdlvchallan|/sap/opu/odata4/sap/zui_delivery_challan_04/srvd/sap/zui_delivery_challan/0001/|DeliveryChallan|ZDLVCHALLAN|DeliveryChallan|display|document-text|Delivery Challan|Carton listing"
"zreturnbox|/sap/opu/odata4/sap/zui_return_box_04/srvd/sap/zui_return_box/0001/|ReturnBox|ZRETURNBOX|ReturnBox|manage|return-request|Unassign Return Boxes|Returns box unassignment"
)

for row in "${APPS[@]}"; do
  IFS='|' read -r MOD URI ENTITY BSP SEMOBJ ACTION ICON TITLE SUBTITLE <<< "$row"
  ID="com.kgpl.${MOD}"
  APP="$ROOT/$MOD"
  echo ">> $MOD  ($ENTITY -> $BSP)"
  rm -rf "$APP"; mkdir -p "$APP/webapp/i18n"

  # ---------- package.json ----------
  cat > "$APP/package.json" <<EOF
{
  "name": "${MOD}",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "build": "ui5 build --clean-dest",
    "deploy": "fiori deploy --config ui5-deploy.yaml --archive-url false",
    "start": "fiori run --open \"index.html\""
  },
  "devDependencies": {
    "@sap/ux-ui5-tooling": "1",
    "@ui5/cli": "3"
  }
}
EOF

  # ---------- ui5.yaml ----------
  cat > "$APP/ui5.yaml" <<EOF
specVersion: "3.0"
metadata:
  name: ${MOD}
type: application
framework:
  name: SAPUI5
  version: "1.120.0"
  libraries:
    - name: sap.m
    - name: sap.ui.core
    - name: sap.fe.templates
EOF

  # ---------- ui5-deploy.yaml ----------
  cat > "$APP/ui5-deploy.yaml" <<EOF
specVersion: "3.0"
metadata:
  name: ${MOD}
type: application
builder:
  resources:
    excludes:
      - "/test/**"
      - "/localService/**"
  customTasks:
    - name: deploy-to-abap
      afterTask: generateCachebusterInfo
      configuration:
        target:
          url: https://122.179.133.205:5200
          client: "500"
        app:
          name: ${BSP}
          package: ZKGPL_FIORI
          transport: KSDK906624
          description: ${TITLE}
        exclude:
          - "/test/"
EOF

  # ---------- webapp/Component.js ----------
  cat > "$APP/webapp/Component.js" <<EOF
sap.ui.define(["sap/fe/core/AppComponent"], function (AppComponent) {
  "use strict";
  return AppComponent.extend("${ID}.Component", {
    metadata: { manifest: "json" }
  });
});
EOF

  # ---------- webapp/index.html ----------
  cat > "$APP/webapp/index.html" <<EOF
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${TITLE}</title>
  <script id="sap-ui-bootstrap"
    src="https://ui5.sap.com/resources/sap-ui-core.js"
    data-sap-ui-theme="sap_horizon"
    data-sap-ui-resourceroots='{"${ID}": "./"}'
    data-sap-ui-oninit="module:sap/ui/core/ComponentSupport"
    data-sap-ui-compatVersion="edge"
    data-sap-ui-async="true"></script>
</head>
<body class="sapUiBody">
  <div data-sap-ui-component data-name="${ID}" data-id="container" data-settings='{"id":"${MOD}"}'></div>
</body>
</html>
EOF

  # ---------- webapp/i18n/i18n.properties ----------
  cat > "$APP/webapp/i18n/i18n.properties" <<EOF
appTitle=${TITLE}
appSubTitle=${SUBTITLE}
appDescription=${TITLE} - ${SUBTITLE}
EOF

  # ---------- webapp/manifest.json ----------
  cat > "$APP/webapp/manifest.json" <<EOF
{
  "_version": "1.65.0",
  "sap.app": {
    "id": "${ID}",
    "type": "application",
    "i18n": "i18n/i18n.properties",
    "applicationVersion": { "version": "1.0.0" },
    "title": "{{appTitle}}",
    "description": "{{appDescription}}",
    "dataSources": {
      "mainService": {
        "uri": "${URI}",
        "type": "OData",
        "settings": { "odataVersion": "4.0" }
      }
    },
    "crossNavigation": {
      "inbounds": {
        "${SEMOBJ}-${ACTION}": {
          "semanticObject": "${SEMOBJ}",
          "action": "${ACTION}",
          "title": "{{appTitle}}",
          "subTitle": "{{appSubTitle}}",
          "icon": "sap-icon://${ICON}",
          "signature": { "parameters": {}, "additionalParameters": "allowed" }
        }
      }
    }
  },
  "sap.ui": {
    "technology": "UI5",
    "icons": { "icon": "sap-icon://${ICON}" },
    "deviceTypes": { "desktop": true, "tablet": true, "phone": true }
  },
  "sap.ui5": {
    "flexEnabled": true,
    "dependencies": {
      "minUI5Version": "1.120.0",
      "libs": { "sap.m": {}, "sap.ui.core": {}, "sap.fe.templates": {} }
    },
    "models": {
      "i18n": {
        "type": "sap.ui.model.resource.ResourceModel",
        "settings": { "bundleName": "${ID}.i18n.i18n" }
      },
      "": {
        "dataSource": "mainService",
        "preload": true,
        "settings": { "operationMode": "Server", "autoExpandSelect": true, "earlyRequests": true }
      }
    },
    "routing": {
      "config": {},
      "routes": [
        { "pattern": ":?query:", "name": "${ENTITY}List", "target": "${ENTITY}List" },
        { "pattern": "${ENTITY}({key}):?query:", "name": "${ENTITY}OP", "target": "${ENTITY}OP" }
      ],
      "targets": {
        "${ENTITY}List": {
          "type": "Component",
          "id": "${ENTITY}List",
          "name": "sap.fe.templates.ListReport",
          "options": {
            "settings": {
              "contextPath": "/${ENTITY}",
              "variantManagement": "Page",
              "initialLoad": "Disabled",
              "navigation": { "${ENTITY}": { "detail": { "route": "${ENTITY}OP" } } }
            }
          }
        },
        "${ENTITY}OP": {
          "type": "Component",
          "id": "${ENTITY}OP",
          "name": "sap.fe.templates.ObjectPage",
          "options": { "settings": { "contextPath": "/${ENTITY}" } }
        }
      }
    },
    "contentDensities": { "compact": true, "cozy": true }
  },
  "sap.fiori": { "registrationIds": [], "archeType": "transactional" }
}
EOF

  # ---------- .gitignore ----------
  cat > "$APP/.gitignore" <<EOF
node_modules/
dist/
EOF
done

echo ""
echo "Done. 5 apps scaffolded under $ROOT :"
for row in "${APPS[@]}"; do IFS='|' read -r MOD _ <<< "$row"; echo "  - $MOD"; done
echo ""
echo "Deploy each:  cd <app> && npm install && npm run deploy"
