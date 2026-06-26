# Sales Contract Status (ZCON_CLOSE / ZCON_CLOSE1 / ZCOREL / ZCON02) — unmanaged RAP

Clean-core replacement for the custom contract lifecycle programs. A read model
over the standard sales-document header **`VBAK`** (contracts, `VBTYP = 'G'`)
plus four static actions that drive the **standard** sales document — no standard
object is modified, nothing custom is persisted.

| Action | Replaces (Z) | Does |
|---|---|---|
| `closeContract` | `ZSOL_CONTRACT_CLOSE` (ZCON_CLOSE) | Reject open quantity / set closed status |
| `completeContract` | `ZSOL_CONTRACT_CLOSE_ONE` (ZCON_CLOSE1) | Close a fully-delivered contract |
| `releaseContract` | `ZSOL_CONTRACT_RELEASE` (ZCOREL) | Remove delivery / billing block |
| `updatePendingRate` | `ZSD_RPT_PCONTRACT_REG_PCON` (ZCON02) | Update net rate on pending items |

Actions are **static** and take the contract id as a parameter, so the standard
**Manage Sales Contracts** adaptation ([`apps/manage-sales-contracts-ext`](../../apps/manage-sales-contracts-ext))
can call them by id from the object page without binding to this service.

## Objects in `src/`
| File | Object | Role |
|---|---|---|
| `zi_sales_contract.ddls.asddls` | `ZI_SalesContract` | Read model over `VBAK` (contracts) |
| `zc_sales_contract.ddls.asddls` | `ZC_SalesContract` | Projection (`transactional_query`) |
| `zi_sales_contract.bdef.asbdef` | Behavior (unmanaged) | 4 static lifecycle actions |
| `zc_sales_contract.bdef.asbdef` | Projection behavior | `use action` x4 |
| `zbp_i_sales_contract.clas.*` | Behavior pool | action handlers (BAPI calls `TODO`) |
| `zd_contract_action.ddls.asddls` | Param | `SalesContract` (+ `Reason`) |
| `zd_pending_rate.ddls.asddls` | Param | `SalesContract` / `SalesContractItem` / `NewRate` |
| `zd_contract_result.ddls.asddls` | Result | `SalesContract` / `NewStatus` / `Message` |
| `zui_contract_status.srvd.srvdsrv` | Service def `ZUI_CONTRACT_STATUS` | exposes `ZC_SalesContract` |

## Wiring (TODO)
Each handler calls `BAPI_SD_SALESDOCUMENT_CHANGE` (reject open qty / clear
`LIFSK`-`FAKSK` / update condition `KBETR`) — see the inline TODOs. Reuse the
existing `ZSOL_*` contract routines where possible. Front-end call pattern is in
the contract adaptation's `SalesContractObjectPageExt.js`.

## Create in ADT
- OData V4 service binding `ZUI_CONTRACT_STATUS_O4` for `ZUI_CONTRACT_STATUS`.

## Branch
Tracked on `claude/fiori-app-extensions-h1nb64`.
