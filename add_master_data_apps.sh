#!/bin/bash
set -e
cd ~/Desktop/Fiori-Apps
mkdir -p master-data-apps

mkdir -p "master-data-apps/cform-allocation-master"
cat > "master-data-apps/cform-allocation-master/README.md" << 'READMEEOF'
# C-Form Allocation Master (Master Data)

**Type:** Managed RAP master (Fiori Elements — generated UI, no custom UI5 code)
**Backend table:** ZCFORM1 (keys SALE_ORG/CUST_CODE/INVOICE_NO)
**Replaces (Z):** ZCFORM1/ZFORM/ZFORMS/ZPCFORM
**Status:** Real table ZCFORM1; pending vs received = FormNumber/FormDate empty vs filled

## Why there's no UI5 project folder here

This master's List Report / Object Page is **generated automatically by SAP
Fiori Elements** from the RAP-managed business object's service binding and
CDS annotations — there is no hand-written UI5 app to check into this repo.
Only the backend (CDS view, behavior definition, service binding) is
version-controlled, in [`cform-master-rap.md`](../../docs/backend-notes/cform-master-rap.md).

This folder exists purely so the master appears alongside the other 33
freestyle/adaptation apps when browsing `Fiori-Apps`, and to make its status
and backend doc easy to find. If this app is confirmed working in KSQ, no
further action is needed here — just make sure the ICF service for the
generated UI (`/sap/bc/ui5_ui5/...` or OData V4 metadata path, per SAP's
Fiori Elements generation) is active, the same class of issue we hit with the
freestyle apps.

READMEEOF

mkdir -p "master-data-apps/checked-packed-by-master"
cat > "master-data-apps/checked-packed-by-master/README.md" << 'READMEEOF'
# Checked/Packed By Master (Master Data)

**Type:** Managed RAP master (Fiori Elements — generated UI, no custom UI5 code)
**Backend table:** ZPP_PCBY (keys SR_NO/PC)
**Replaces (Z):** ZPCBY
**Status:** Refit to real table ZPP_PCBY

## Why there's no UI5 project folder here

This master's List Report / Object Page is **generated automatically by SAP
Fiori Elements** from the RAP-managed business object's service binding and
CDS annotations — there is no hand-written UI5 app to check into this repo.
Only the backend (CDS view, behavior definition, service binding) is
version-controlled, in [`checked-by-master-rap.md`](../../docs/backend-notes/checked-by-master-rap.md).

This folder exists purely so the master appears alongside the other 33
freestyle/adaptation apps when browsing `Fiori-Apps`, and to make its status
and backend doc easy to find. If this app is confirmed working in KSQ, no
further action is needed here — just make sure the ICF service for the
generated UI (`/sap/bc/ui5_ui5/...` or OData V4 metadata path, per SAP's
Fiori Elements generation) is active, the same class of issue we hit with the
freestyle apps.

READMEEOF

mkdir -p "master-data-apps/digital-signature-master"
cat > "master-data-apps/digital-signature-master/README.md" << 'READMEEOF'
# Digital Signature Master (Master Data)

**Type:** Managed RAP master (Fiori Elements — generated UI, no custom UI5 code)
**Backend table:** ZTDIGI_SIGN (key BUKRS)
**Replaces (Z):** ZDIGI
**Status:** Refit to real table ZTDIGI_SIGN

## Why there's no UI5 project folder here

This master's List Report / Object Page is **generated automatically by SAP
Fiori Elements** from the RAP-managed business object's service binding and
CDS annotations — there is no hand-written UI5 app to check into this repo.
Only the backend (CDS view, behavior definition, service binding) is
version-controlled, in [`digital-signature-master-rap.md`](../../docs/backend-notes/digital-signature-master-rap.md).

This folder exists purely so the master appears alongside the other 33
freestyle/adaptation apps when browsing `Fiori-Apps`, and to make its status
and backend doc easy to find. If this app is confirmed working in KSQ, no
further action is needed here — just make sure the ICF service for the
generated UI (`/sap/bc/ui5_ui5/...` or OData V4 metadata path, per SAP's
Fiori Elements generation) is active, the same class of issue we hit with the
freestyle apps.

READMEEOF

mkdir -p "master-data-apps/export-details-master"
cat > "master-data-apps/export-details-master/README.md" << 'READMEEOF'
# Export Details Master (Master Data)

**Type:** Managed RAP master (Fiori Elements — generated UI, no custom UI5 code)
**Backend table:** ZEXP (keys VBELN/KSCHL)
**Replaces (Z):** ZMBR2
**Status:** Refit to real table ZEXP

## Why there's no UI5 project folder here

This master's List Report / Object Page is **generated automatically by SAP
Fiori Elements** from the RAP-managed business object's service binding and
CDS annotations — there is no hand-written UI5 app to check into this repo.
Only the backend (CDS view, behavior definition, service binding) is
version-controlled, in [`export-detail-master-rap.md`](../../docs/backend-notes/export-detail-master-rap.md).

This folder exists purely so the master appears alongside the other 33
freestyle/adaptation apps when browsing `Fiori-Apps`, and to make its status
and backend doc easy to find. If this app is confirmed working in KSQ, no
further action is needed here — just make sure the ICF service for the
generated UI (`/sap/bc/ui5_ui5/...` or OData V4 metadata path, per SAP's
Fiori Elements generation) is active, the same class of issue we hit with the
freestyle apps.

READMEEOF

mkdir -p "master-data-apps/job-master"
cat > "master-data-apps/job-master/README.md" << 'READMEEOF'
# Job Master (Master Data)

**Type:** Managed RAP master (Fiori Elements — generated UI, no custom UI5 code)
**Backend table:** ZPP_JOBN (key JOBNO)
**Replaces (Z):** ZJOB01/02/03(N)
**Status:** Refit to real table ZPP_JOBN

## Why there's no UI5 project folder here

This master's List Report / Object Page is **generated automatically by SAP
Fiori Elements** from the RAP-managed business object's service binding and
CDS annotations — there is no hand-written UI5 app to check into this repo.
Only the backend (CDS view, behavior definition, service binding) is
version-controlled, in [`job-master-rap.md`](../../docs/backend-notes/job-master-rap.md).

This folder exists purely so the master appears alongside the other 33
freestyle/adaptation apps when browsing `Fiori-Apps`, and to make its status
and backend doc easy to find. If this app is confirmed working in KSQ, no
further action is needed here — just make sure the ICF service for the
generated UI (`/sap/bc/ui5_ui5/...` or OData V4 metadata path, per SAP's
Fiori Elements generation) is active, the same class of issue we hit with the
freestyle apps.

READMEEOF

mkdir -p "master-data-apps/merge-details-master"
cat > "master-data-apps/merge-details-master/README.md" << 'READMEEOF'
# Merge Details Master (Master Data)

**Type:** Managed RAP master (Fiori Elements — generated UI, no custom UI5 code)
**Backend table:** ZPP_MERGE (keys AURNR/GRADE/ENDUSE)
**Replaces (Z):** ZMERGE
**Status:** Refit to real table ZPP_MERGE

## Why there's no UI5 project folder here

This master's List Report / Object Page is **generated automatically by SAP
Fiori Elements** from the RAP-managed business object's service binding and
CDS annotations — there is no hand-written UI5 app to check into this repo.
Only the backend (CDS view, behavior definition, service binding) is
version-controlled, in [`merge-master-rap.md`](../../docs/backend-notes/merge-master-rap.md).

This folder exists purely so the master appears alongside the other 33
freestyle/adaptation apps when browsing `Fiori-Apps`, and to make its status
and backend doc easy to find. If this app is confirmed working in KSQ, no
further action is needed here — just make sure the ICF service for the
generated UI (`/sap/bc/ui5_ui5/...` or OData V4 metadata path, per SAP's
Fiori Elements generation) is active, the same class of issue we hit with the
freestyle apps.

READMEEOF

mkdir -p "master-data-apps/packing-material-master"
cat > "master-data-apps/packing-material-master/README.md" << 'READMEEOF'
# Packing Material Master (Master Data)

**Type:** Managed RAP master (Fiori Elements — generated UI, no custom UI5 code)
**Backend table:** ZPACK_MAST (keys PTYPE/ARBPL/MATNR)
**Replaces (Z):** ZPACK_MAST
**Status:** Refit to real table ZPACK_MAST

## Why there's no UI5 project folder here

This master's List Report / Object Page is **generated automatically by SAP
Fiori Elements** from the RAP-managed business object's service binding and
CDS annotations — there is no hand-written UI5 app to check into this repo.
Only the backend (CDS view, behavior definition, service binding) is
version-controlled, in [`packing-material-master-rap.md`](../../docs/backend-notes/packing-material-master-rap.md).

This folder exists purely so the master appears alongside the other 33
freestyle/adaptation apps when browsing `Fiori-Apps`, and to make its status
and backend doc easy to find. If this app is confirmed working in KSQ, no
further action is needed here — just make sure the ICF service for the
generated UI (`/sap/bc/ui5_ui5/...` or OData V4 metadata path, per SAP's
Fiori Elements generation) is active, the same class of issue we hit with the
freestyle apps.

READMEEOF

mkdir -p "master-data-apps/recipe-master"
cat > "master-data-apps/recipe-master/README.md" << 'READMEEOF'
# Recipe Master (Master Data)

**Type:** Managed RAP master (Fiori Elements — generated UI, no custom UI5 code)
**Backend table:** ZPP_RECEIPE (19 fields, 5-part key)
**Replaces (Z):** ZRECP01/02/03
**Status:** Refit to real table ZPP_RECEIPE

## Why there's no UI5 project folder here

This master's List Report / Object Page is **generated automatically by SAP
Fiori Elements** from the RAP-managed business object's service binding and
CDS annotations — there is no hand-written UI5 app to check into this repo.
Only the backend (CDS view, behavior definition, service binding) is
version-controlled, in [`recipe-master-rap.md`](../../docs/backend-notes/recipe-master-rap.md).

This folder exists purely so the master appears alongside the other 33
freestyle/adaptation apps when browsing `Fiori-Apps`, and to make its status
and backend doc easy to find. If this app is confirmed working in KSQ, no
further action is needed here — just make sure the ICF service for the
generated UI (`/sap/bc/ui5_ui5/...` or OData V4 metadata path, per SAP's
Fiori Elements generation) is active, the same class of issue we hit with the
freestyle apps.

READMEEOF

mkdir -p "master-data-apps/schedule-master"
cat > "master-data-apps/schedule-master/README.md" << 'READMEEOF'
# Schedule Master (Master Data)

**Type:** Managed RAP master (Fiori Elements — generated UI, no custom UI5 code)
**Backend table:** ZPP_SCHEDULEN (keys SCHNO/GJAHR)
**Replaces (Z):** ZSCH01/02/03(N)
**Status:** Refit to real table ZPP_SCHEDULEN

## Why there's no UI5 project folder here

This master's List Report / Object Page is **generated automatically by SAP
Fiori Elements** from the RAP-managed business object's service binding and
CDS annotations — there is no hand-written UI5 app to check into this repo.
Only the backend (CDS view, behavior definition, service binding) is
version-controlled, in [`schedule-master-rap.md`](../../docs/backend-notes/schedule-master-rap.md).

This folder exists purely so the master appears alongside the other 33
freestyle/adaptation apps when browsing `Fiori-Apps`, and to make its status
and backend doc easy to find. If this app is confirmed working in KSQ, no
further action is needed here — just make sure the ICF service for the
generated UI (`/sap/bc/ui5_ui5/...` or OData V4 metadata path, per SAP's
Fiori Elements generation) is active, the same class of issue we hit with the
freestyle apps.

READMEEOF

mkdir -p "master-data-apps/shade-master"
cat > "master-data-apps/shade-master/README.md" << 'READMEEOF'
# Shade Master (Master Data)

**Type:** Managed RAP master (Fiori Elements — generated UI, no custom UI5 code)
**Backend table:** ZDD_SHADE
**Replaces (Z):** ZDD_SHADE
**Status:** Source authored (table + service binding to create in ADT). Also provides value-help for F1873 and F3069.

## Why there's no UI5 project folder here

This master's List Report / Object Page is **generated automatically by SAP
Fiori Elements** from the RAP-managed business object's service binding and
CDS annotations — there is no hand-written UI5 app to check into this repo.
Only the backend (CDS view, behavior definition, service binding) is
version-controlled, in [`shade-master-rap.md`](../../docs/backend-notes/shade-master-rap.md).

This folder exists purely so the master appears alongside the other 33
freestyle/adaptation apps when browsing `Fiori-Apps`, and to make its status
and backend doc easy to find. If this app is confirmed working in KSQ, no
further action is needed here — just make sure the ICF service for the
generated UI (`/sap/bc/ui5_ui5/...` or OData V4 metadata path, per SAP's
Fiori Elements generation) is active, the same class of issue we hit with the
freestyle apps.

READMEEOF

mkdir -p "master-data-apps/transport-code-master"
cat > "master-data-apps/transport-code-master/README.md" << 'READMEEOF'
# Transport Code Master (Master Data)

**Type:** Managed RAP master (Fiori Elements — generated UI, no custom UI5 code)
**Backend table:** ZTRANS (keys ZZTRCODE/ZZTRCKNO)
**Replaces (Z):** ZTRANS
**Status:** Refit to real table ZTRANS

## Why there's no UI5 project folder here

This master's List Report / Object Page is **generated automatically by SAP
Fiori Elements** from the RAP-managed business object's service binding and
CDS annotations — there is no hand-written UI5 app to check into this repo.
Only the backend (CDS view, behavior definition, service binding) is
version-controlled, in [`transport-code-master-rap.md`](../../docs/backend-notes/transport-code-master-rap.md).

This folder exists purely so the master appears alongside the other 33
freestyle/adaptation apps when browsing `Fiori-Apps`, and to make its status
and backend doc easy to find. If this app is confirmed working in KSQ, no
further action is needed here — just make sure the ICF service for the
generated UI (`/sap/bc/ui5_ui5/...` or OData V4 metadata path, per SAP's
Fiori Elements generation) is active, the same class of issue we hit with the
freestyle apps.

READMEEOF

mkdir -p "master-data-apps/truck-master"
cat > "master-data-apps/truck-master/README.md" << 'READMEEOF'
# Truck Master (Master Data)

**Type:** Managed RAP master (Fiori Elements — generated UI, no custom UI5 code)
**Backend table:** ZTB_TRUCK_MSTR (key TRUCKNO)
**Replaces (Z):** ZTRUCK
**Status:** Refit to real table ZTB_TRUCK_MSTR

## Why there's no UI5 project folder here

This master's List Report / Object Page is **generated automatically by SAP
Fiori Elements** from the RAP-managed business object's service binding and
CDS annotations — there is no hand-written UI5 app to check into this repo.
Only the backend (CDS view, behavior definition, service binding) is
version-controlled, in [`truck-master-rap.md`](../../docs/backend-notes/truck-master-rap.md).

This folder exists purely so the master appears alongside the other 33
freestyle/adaptation apps when browsing `Fiori-Apps`, and to make its status
and backend doc easy to find. If this app is confirmed working in KSQ, no
further action is needed here — just make sure the ICF service for the
generated UI (`/sap/bc/ui5_ui5/...` or OData V4 metadata path, per SAP's
Fiori Elements generation) is active, the same class of issue we hit with the
freestyle apps.

READMEEOF

git add master-data-apps/
git status --short
git commit -m "Add master-data-apps: doc stubs for the 12 RAP-managed masters (Fiori Elements generated UI, no custom UI5 code) so the full 45-app portfolio is visible alongside apps/"
git push origin main
echo "=== DONE. Folder count now: ==="
find apps master-data-apps -mindepth 1 -maxdepth 1 -type d | wc -l