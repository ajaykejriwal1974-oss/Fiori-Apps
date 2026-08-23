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

