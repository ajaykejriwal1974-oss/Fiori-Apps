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

> The read model now sources the box table **`ZPP_PACK`** directly (was an early
> `ZVBAP`-based draft), so `Plant` (`pack.werks`), `Material`, `Grade`, `NetWeight`,
> `PackListDate` and `Status` (`'P'` when `PKLST` assigned, else `'O'`) all populate
> from the one table — no join to a non-CDS-selectable table.

## Actions — real logic (ported from ZSD_PACKING_LIST_01)
Actions are **instance-bound** (not static): the selected box(es) arrive in the
handler's `keys` (`BoxNumber` + `BoxYear` = the `ZPP_PACK` primary key), so each
UPDATE hits exactly the selected row — no `SELECT SINGLE gjahr` guess.
- `createPackingList` / `changePackingList` — `UPDATE zpp_pack SET vbeln/posnr/pklst/pldate` per box (the packing list is the PKLST assignment on the box table)
- `deletePackingList` — `INSERT zplistd` (soft-delete log) then clear the assignment

The frontend invokes each action **once per selected row's context**
(`oModel.bindContext(SERVICE_NS + ".createPackingList(...)", oContext)`); Create/Change
open a small dialog to enter `SalesOrder` / `SalesOrderItem` / `PackListItem`.

> **✅ Write path VERIFIED — 23 Jul 2026.** Test on throwaway box `992000000/2020`:
> `createPackingList` set `PackListItem 0→999999`, `PackListDate null→2026-07-23`,
> `Status O→P` and it **persisted** across a fresh read. Restore ran clean
> (`deletePackingList` → `BoxesAffected:1`, box unassigned). No saver class needed —
> the unmanaged actions run direct SQL and the OData action request's LUW commits.
> (Earlier static-action attempt reported `BoxesAffected:0` because `keys` was empty;
> the instance-action refactor fixed it.) No `COMMIT WORK` in handlers (forbidden in RAP).

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
