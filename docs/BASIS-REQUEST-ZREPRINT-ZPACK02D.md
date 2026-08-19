# Basis request — ZREPRINT and ZPACK02D access

**Raised by:** Ajay Kejriwal
**Date:** 2026-08-19
**Systems:** KSD (dev) → KSQ (quality) → production
**Type:** authorisation / role assignment — **no development required**

---

## Why this is not a development item

The scanned space list flags `ZREPRINT` and `ZPACK02D` as "missing apps". They
are not development gaps:

| Item | Reality | Action |
| --- | --- | --- |
| `ZPACK02D` (`ZPP_PACK_MODULE_DYING`) | **Already replaced** by the Fiori app `apps/dyeing-packing` (BSP + RAP service, in `ZKGPL_FIORI`). The users cannot see the tile. | Assign the catalog/group + role so the tile appears in the space. |
| `ZREPRINT` (`ZCRPG_PP_SLIP`) | Box-slip **reprint**, a print driver. Per `docs/PRT-OUTPUT-MANAGEMENT.md` §4 it migrates to an Output Management form template, not to a bespoke app. That work is not scheduled yet. | Grant the GUI transaction as an **interim** measure so packing can reprint slips. |

Both are access items. Building an app for either would duplicate work already
done (`ZPACK02D`) or pre-empt the OM template design (`ZREPRINT`).

---

## Request 1 — Fiori tile access: Dyeing Packing (replaces ZPACK02D)

Please assign the following to the packing operators' business role so the tile
resolves in the **Production / Packing** space.

| What | Value |
| --- | --- |
| BSP application | `ZDYEING_PACK` |
| Semantic object / action | `HandlingUnit` / `packDyeingKejriwal` |
| OData V4 service | `/sap/opu/odata4/sap/zui_packing_04/srvd/sap/zui_packing/0001/` (binding `ZUI_PACKING_04`) |
| Space / page | Production (or Packing, per current FLP layout) |

Steps for Basis:

1. `/UI2/FLPD_CUST` — confirm the target mapping and tile exist in the custom
   catalog and are assigned to the space's page.
2. Add the catalog to the packing business role (`PFCG`).
3. `/IWFND/MAINT_SERVICE` (or the V4 equivalent, `/IWBEP` service group) — check
   the OData service is registered and the role carries `S_SERVICE` for it.
4. Assign the role to the packing user group.
5. Ask one operator to clear the FLP cache (`Ctrl+Shift+R`) and confirm the tile
   appears and loads data.

**Expected result:** operators run dyeing packing from Fiori; `ZPACK02D` in SAP
GUI is no longer needed and can be dropped from the request below.

---

## Request 2 — SAP GUI transaction access: ZREPRINT (interim)

Until the box slip moves to an Output Management template, packing needs the
existing reprint transaction.

| Object | Field | Value |
| --- | --- | --- |
| `S_TCODE` | `TCD` | `ZREPRINT` |
| `S_PROGRAM` | `P_GROUP` / `P_ACTION` | authorisation group of `ZCRPG_PP_SLIP`; action `SUBMIT` |
| `S_SPO_ACT` / `S_SPO_DEV` | — | output device(s) used by packing (label / slip printer) |

Scope this to the packing user group only, and to the plant(s) actually
packing — this is a reprint of an existing document, so it should not be given
to everyone with production display access.

If the same operators also reprint pallet labels, please add on the same
request:

- `ZREPRINTPLT` (`ZCRPG_PP_SLIP_BIGPLT`) — big-pallet label reprint
- `ZREPRINTR` (`ZCRPT_PP_003`) — reprint report

---

## Follow-up (development side, not part of this request)

`ZREPRINT` is tracked in `docs/PRT-OUTPUT-MANAGEMENT.md` §4 (labels / barcode /
stickers, 10 transactions). The clean-core target is **one parameterised Adobe
form template with barcode fields**, routed through Output Management to the
label printer, shared across `ZBARGR`, `ZBOXPRT`, `ZSBAR`, `ZSTICKER`,
`ZPAL_PRINT`, `ZPAL_REPRINT`, `ZREPRINT`, `ZREPRINTPLT`.

That is a single template project, not eight programs. It should be planned
once the packing apps are live in production — at which point the interim GUI
access above can be withdrawn.

---

## Sign-off

| | Name | Date |
| --- | --- | --- |
| Requested by | Ajay Kejriwal | 2026-08-19 |
| Approved by (process owner) | | |
| Implemented by (Basis) | | |
