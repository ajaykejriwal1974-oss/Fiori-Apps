# Sales Order Status (ZSOCLOSE / ZSOCLOSE1) — unmanaged RAP

Clean-core replacement for the custom sales-order close programs. A read model
over the standard sales-document header **`VBAK`** (orders, `VBTYP = 'C'`) plus
close actions that drive the **standard** sales document — no standard object is
modified, nothing custom is persisted.

| Action | Replaces (Z) | Does |
|---|---|---|
| `closeSalesOrder` | `ZSOL_SALESORDER_CLOSE` (ZSOCLOSE) | Reject open quantity / set closed status |
| `closeOrderProgram` | `ZSOL_SO_CLOSE` (ZSOCLOSE1) | Mass-close variant over a selection |

Static actions take the order id as a parameter, so the standard **Manage Sales
Orders** adaptation ([`apps/manage-sales-orders-ext`](../../apps/manage-sales-orders-ext))
can call `closeSalesOrder` by id from the object page.

## Objects in `src/`
| File | Object | Role |
|---|---|---|
| `zi_sales_order_status.ddls.asddls` | `ZI_SalesOrderStatus` | Read model over `VBAK` (orders) |
| `zc_sales_order_status.ddls.asddls` | `ZC_SalesOrderStatus` | Projection (`transactional_query`) |
| `zi_sales_order_status.bdef.asbdef` | Behavior (unmanaged) | 2 static close actions |
| `zc_sales_order_status.bdef.asbdef` | Projection behavior | `use action` x2 |
| `zbp_i_sales_order_status.clas.*` | Behavior pool | action handlers (BAPI calls `TODO`) |
| `zd_order_action.ddls.asddls` | Param | `SalesOrder` (+ `Reason`) |
| `zd_order_result.ddls.asddls` | Result | `SalesOrder` / `NewStatus` / `Message` |
| `zui_sales_order_status.srvd.srvdsrv` | Service def `ZUI_SALES_ORDER_STATUS` | exposes `ZC_SalesOrderStatus` |

## Wiring (TODO)
Each handler calls `BAPI_SD_SALESDOCUMENT_CHANGE` (reject open qty / set status) —
see inline TODOs. Reuse the existing `ZSOL_*` close routines where possible.

## Create in ADT
- OData V4 service binding `ZUI_SALES_ORDER_STATUS_O4` for `ZUI_SALES_ORDER_STATUS`.

## Branch
Tracked on `claude/fiori-app-extensions-h1nb64`.
