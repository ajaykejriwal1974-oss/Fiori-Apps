# MTOS Process (ZMTOS + ZHUINV) — unmanaged RAP (consolidated)

**Consolidation P1** of the [custom-app audit](../../docs/CUSTOM-APP-AUDIT.md):
`ZMTOS` (transfer MTO→MTS stock) and `ZHUINV` (create physical-inventory
document) are the **same legacy program `ZSOL_MTOS_PROCESS`** — two steps of one
flow. They are now **one** service over the sales-order stock (`MSKA`) exposing
both actions. (Replaces the former `mto-mts-transfer-rap` + `hu-phys-inventory-rap`.)

| Action | Replaces | BAPI | Status |
|---|---|---|---|
| `convertToMts` | ZMTOS | `BAPI_GOODSMVT_CREATE` (movement 411 E, special stock E) | **wired ✅** (VERIFY gm_code/move type) |
| `createPhysInvDoc` | ZHUINV | `BAPI_MATPHYSINV_CREATE_MULT` | TODO |

## Objects in `src/`
| File | Object | Role |
|---|---|---|
| `zi_mtos_process.ddls.asddls` | `ZI_MtosStock` | Read model over `MSKA` (sales-order stock) |
| `zc_mtos_process.ddls.asddls` | `ZC_MtosStock` | Projection (`transactional_query`) |
| `zi_mtos_process.bdef.asbdef` | Behavior (unmanaged) | both static actions |
| `zc_mtos_process.bdef.asbdef` | Projection behavior | `use action` x2 |
| `zbp_i_mtos_process.clas.*` | Behavior pool | action handlers (BAPIs TODO) |
| `zd_mto_mts*.ddls` / `zd_phys_inv*.ddls` | Params / results | per action |
| `zui_mtos_process.srvd.srvdsrv` | Service def `ZUI_MTOS_PROCESS` | exposes `ZC_MtosStock` |

Front-end: [`apps/mtos-process`](../../apps/mtos-process) — one worklist with both
actions (Convert to MTS · Create Phys. Inv. Doc).

## Create in ADT
- OData V4 service binding `ZUI_MTOS_PROCESS_O4`.

## Branch
Tracked on `claude/fiori-app-extensions-h1nb64`.
