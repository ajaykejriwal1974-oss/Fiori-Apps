# Dispatch Correction (ZDSP_CORR) — unmanaged RAP service

Clean-core replacement for **`ZSOL_DISPATCH_CORRECTION`**. A read model over the
existing dispatch table **`ZSOL_HUDISPATCH`** (reusing **`ZPP_PACK`** for box
detail) plus a static action that re-assigns selected boxes to a new sales
order / item / status. **Unmanaged** — the update is applied to the existing
tables, no new persistence.

## Objects in `src/`
| File | Object | Role |
|---|---|---|
| `zi_dispatch_box.ddls.asddls` | `ZI_DispatchBox` | Read model: `ZSOL_HUDISPATCH` ⋈ `ZPP_PACK` |
| `zc_dispatch_box.ddls.asddls` | `ZC_DispatchBox` | Projection (`transactional_query`) |
| `zi_dispatch_box.bdef.asbdef` | Behavior (unmanaged) | `static action correctDispatch` |
| `zc_dispatch_box.bdef.asbdef` | Projection behavior | `use action correctDispatch` |
| `zbp_i_dispatch_box.clas.*` | Behavior pool | `correctDispatch` handler (BAPI/update `TODO`) |
| `zd_dispatch_correct.ddls.asddls` | Param (header) | `NewSalesOrder` / `NewSalesOrderItem` / `NewStatus` + `_Item` |
| `zd_dispatch_correct_item.ddls.asddls` | Param (item) | `BoxNumber` (one per selected box) |
| `zd_dispatch_result.ddls.asddls` | Result | `BoxesUpdated` + `Message` |
| `zui_dispatch_correction.srvd.srvdsrv` | Service def `ZUI_DISPATCH_CORRECTION` | exposes `ZC_DispatchBox` |

## Read model
`ZSOL_HUDISPATCH`: `BOXNO` (key), `SO`, `SO_ITEM`, `PCK_LST`, `ERDAT`, `TIME`,
`STATUS`; joined to `ZPP_PACK` (`BOXNO`) for `MATNR` / `GRADE` / `NETWT`.

> `ZPP_PACK` is keyed by `BOXNO` + `GJAHR` — confirm the join (year predicate or
> "latest GJAHR") against your data before activating.

## Wiring (TODO)
`correctDispatch` updates `ZSOL_HUDISPATCH` (SO / item / status) for each box and
keeps `ZPP_PACK` in sync. If a box is already invoiced/posted, the goods movement
must be reversed first. Reuse the existing `ZSOL_DISPATCH_CORRECTION` routine
where possible. Front-end: [`apps/dispatch-correction`](../../apps/dispatch-correction).

## Create in ADT
- OData V4 UI service binding `ZUI_DISPATCH_CORRECTION_O4` for service definition
  `ZUI_DISPATCH_CORRECTION`.
- Reuse existing `ZSOL_F4*` value helps for sales order / material fields.

## Branch
Tracked on `claude/fiori-app-extensions-h1nb64`.
