# Packing List (ZPLIST01/02/03 + A/T/N/D variants) — custom Fiori app

**Status: LIVE on KSD (client 500)** — built end-to-end 23 Jul 2026 via ADT REST +
the Eclipse ADT MCP bridge. Backend active, OData service published, app deployed,
FLP tile resolves and renders live data.

Freestyle SAPUI5 worklist app, the clean-core replacement for the **14-transaction
ZPLIST family** (`ZPLIST01/02/03`, `ZPLISTD` and their `A` (IPL), `T` (HSM), `N`
variants — programs `ZSD_PACKING_LIST_01 / _IPL / _HSM / _N`). The plant/format
suffixes collapse into a single app; Create / Change / Delete are three actions on
one worklist.

Binds to the OData V4 service of [`backend/packing-list-rap`](../../backend/packing-list-rap)
(`PackingList` entity set).

## Worklist columns
`SalesOrder`, `SalesOrderItem`, `PackListItem`, `BoxNumber`, `Plant`, `Material`,
`Grade`, `NetWeight`, `Status`

> The **Plant** column renders blank: `ZVBAP` is not a CDS-selectable transparent
> table on KSD, so the Plant field was dropped from the read model (see backend
> README). The column is harmless but cosmetic — remove it from `Worklist.view.xml`
> (and re-source Plant from the confirmed field) on the next redeploy.

## Actions — real logic (ported from ZSD_PACKING_LIST_01)
- `createPackingList` / `changePackingList` — `UPDATE zpp_pack SET vbeln/posnr/pklst/pldate` per box (the packing list is the PKLST assignment on the box table)
- `deletePackingList` — `INSERT zplistd` (soft-delete log) then clear the assignment

> **⚠️ Write path unverified.** The behavior is *unmanaged* and activation flagged
> "SAVER not implemented" — the actions run direct SQL and rely on the OData action
> request's implicit commit. **Before end users use the buttons on live orders:**
> select one throwaway box → Create → confirm in SE16 that `ZPP_PACK-PKLST` updated
> and persisted. If it reverts, a saver class is needed (small, known fix).

## Live objects on KSD (package ZKGPL_FIORI, transport KSDK906624)
| Object | Type |
|---|---|
| `ZI_PACKING_LIST` / `ZC_PACKING_LIST` | CDS interface + projection |
| `ZD_PACKING_LIST_IMPORT` / `_RESULT` | abstract entities |
| `ZI_/ZC_PACKING_LIST` behavior defs + `ZBP_I_PACKING_LIST` | RAP behavior + pool |
| `ZUI_PACKING_LIST` | service definition |
| `ZUI_PACKING_LIST_04` | OData V4 UI service binding (published via /IWFND/V4_ADMIN) |
| BSP `ZPACKING_LIST` | deployed UI |
| FLP target mapping + tile | `PackingList` / `manageKejriwal` in catalog ZKGPL_BC_CUSTOM |

## Retires
`ZPLIST01, ZPLIST01A, ZPLIST01T, ZPLIST02, ZPLIST02A, ZPLIST02N, ZPLIST02T,
ZPLIST03, ZPLIST03A, ZPLIST03N, ZPLIST03T, ZPLISTD, ZPLISTDA, ZPLISTDT`
(print output `ZPLISTP` stays a classic print program by decision).

## Note — client role
Service-binding **publish** was blocked in client 500 (role = Customizing,
`T000-CCCATEGORY='C'`) and done via `/IWFND/V4_ADMIN` → Publish Service Groups
instead of Eclipse's local publish. Same client-role note applies to future apps
(Basis: SCC4 client role) — see the FLP fix runbook.
