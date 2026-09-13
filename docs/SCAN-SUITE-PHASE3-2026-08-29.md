# Scan Suite — Phase 3: server-side session enforcement

System KSD · client 500 · package `ZSOL_ISCAN` · transport **KSDK906759**
Date 2026-08-29

## Why this exists

The handheld reaches SAP under one shared SAP account (`FIORI_USER`). The app
login identifies *which person* is using it, but until today that check lived
only in the browser: anyone holding the shared credential could call the OData
services directly and skip the login screen. The access-control spec called
this out and deferred the fix to Phase 2/3. This is that fix.

**Proof it was real, and that it now isn't.** Before: a plain browser tab on

    /sap/opu/odata/sap/ZSOL_LOC_ISCAN_SRV/LocationSet?$format=json

returned all 25 warehouse locations to anyone who authenticated as the shared
account. After: the same call returns

    /IWBEP/CX_MGW_BUSI_EXCEPTION — "Not signed in"

## The mechanism

`ZCL_ZSOL_APP_AUTH` — new, public, `create private`, all static. One line at
the head of any service method:

```abap
DATA(ls_session) = zcl_zsol_app_auth=>check_request(
  it_header  = io_tech_request_context->get_request_headers( )
  iv_feature = 'LOC' ).
```

The token travels in an **`X-Scan-Token`** HTTP header rather than as an entity
property. That matters: `get_request_headers( )` exists on every tech request
context — entityset, entity, create, update, delete, function import — so the
same call works in any DPC method and no MPC has to change.

Session, user row and grants are re-read on every request. Nothing is cached,
so revoking somebody takes effect on their next scan rather than when their
session lapses.

### The `ISCAN_APP` exemption

`GC_SERVICE_USERS = ';ISCAN_APP;'`.

SOLSYNCH's own Android scanner calls several of these services live — visible
in `/IWFND/SU_STATS` as user `ISCAN_APP` with an `okhttp/3.8.0` client. It has
no app login and carries no token, so a blanket check would have taken it down
silently. It is let through by SAP user name.

This is not a hole. That app holds its own SAP credential, separate from the
shared warehouse account this mechanism exists to neutralise. Anyone holding
`FIORI_USER` still gets nowhere without a session. Remove the entry the day
that app stops calling.

## What is guarded

| Service | Class | Guard |
|---|---|---|
| `ZSOL_LOC_ISCAN_SRV` | `ZCL_ZSOL_LOC_ISCAN_DPC_EXT` | reads: session · create location: `ADDLOC` · box scan: `LOC` |
| `ZSOL_CHALLAN_PACK_SRV_SRV` | `ZCL_ZSOL_CHALLAN_PACK__DPC_EXT` | reads: session · create challan: `CHALLAN` |
| `ZSOL_HU_ISCAN_SRV` | `ZCL_ZSOL_HU_ISCAN_DPC_EXT` | `CREATE_DEEP_ENTITY`: `PACK` |
| `ZSOL_PHYS_INV_POST_SRV` | `ZCL_ZSOL_PHYS_INV_POST_DPC_EXT` | `CREATE_DEEP_ENTITY`: `INV` |
| `ZSOL_DISPATCH_ISCAN_SRV` | `ZCL_ZSOL_DISPATCH_ISCA_DPC_EXT` | `CREATE_DEEP_ENTITY` + `UPDATE_ENTITY`: `DISPATCH` |
| `ZSOL_PICKUPLOAD_SRV_01` | `ZCL_PICKUPLOAD_DPC_EXT` | `CREATE_DEEP_ENTITY`: `PICK` |

Reads ask only for a valid session; writes additionally require the screen they
belong to. Reads are deliberately not screen-scoped because several screens
read the same entity sets — Packing List and Reconciliation both look up where
a box is.

## What is NOT guarded, and why

**`ZSOL_PICK_DOWNLOAD_SRV` (`ZCL_PICK_DOWNLOAD_DPC_EXT`) — blocked.**
The class is locked in **KSDK906244**, a modifiable request owned by
`SOLSYNCH`, open since 2026-08-14. The edit is written and ready; it needs
SOLSYNCH to release that request. Until then this service returns Sales Order,
box, weight and customer data to anyone with the shared credential.

**Four CDS-published services — not guardable this way.**
`ZSOL_SO_PICK_PEND_CDS`, `ZSOL_PLIST_CDS`, `ZSOL_HUINV_HDR_PUSH_CDS`,
`ZSOL_HUINV_ITM_PUSH_CDS` all run on `CL_SADL_GTK_EXPOSURE_DPC`, the generic
CDS exposure provider. There is no DPC_EXT to extend. Options if this matters:
re-expose them through a SEGW project, or accept them as read-only leakage.
Worth confirming whether `..._PUSH_CDS` really only reads — the name suggests
otherwise, and the app POSTs to `HUInvHdrSet`.

## Warning for whoever maintains this

Four of the six guarded classes belong to **SOLSYNCH**. A vendor re-import will
silently drop the check — the service keeps working, it just stops asking. Each
edited class carries a comment saying so. If SOLSYNCH ships a new version of
any of them, put the `CHECK_REQUEST` line back and re-test.

## Still open

- **Camera is blocked server-side.** SAP sends
  `Feature-Policy: … camera 'none' …` with `index.html`, so no device can use
  the barcode scanner. Basis needs to allow `camera 'self'` for
  `/sap/bc/bsp/sap/zsol_scan_suite/*` (look at `icm/HTTP/mod_*` and the rewrite
  rules file it points to), and ideally also emit
  `Permissions-Policy: camera=(self)`. A trusted certificate is needed too —
  a page with a certificate error is not a secure context, and powerful
  features stay blocked there regardless of the header.
- **`SCAN_USER` still records the shared account.** The service now knows who
  is signed in; the field is `SYUNAME` (12 chars) and app names are 20, which
  is the only reason it wasn't changed. Per-person accountability was half the
  point of this work.
- **Only one app user exists** (`ADMIN`). No operator accounts, so the
  restricted-user path has never run.
- **Phase 4 — company/plant filtering — not started.** `ZSOL_APP_UORG` is read
  only by the auth service and the bootstrap report. The session already
  carries the person's orgs, so the plumbing is in place.
- **`ZCL_ZSOL_APP_AUTH_DPC_EXT` still has its own private `CHECK_TOKEN`.**
  Duplicated logic; folding it into the shared class is a small change,
  deliberately not done mid-test because it touches the login path.
