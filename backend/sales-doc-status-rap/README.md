# Sales Document Status — unmanaged RAP (consolidated)

**Consolidation P2** of the [custom-app audit](../../docs/CUSTOM-APP-AUDIT.md):
the former `contract-status-rap` and `sales-order-status-rap` had **identical
read models** over `VBAK` (differing only by `VBTYP = 'G'` vs `'C'`). Merged into
**one** service over `VBAK` (contracts + orders), `DocumentCategory` as a
dimension, exposing **all six** lifecycle actions.

| Action | Replaces | Doc |
|---|---|---|
| `closeContract` | ZSOL_CONTRACT_CLOSE (ZCON_CLOSE) | contract |
| `completeContract` | ZSOL_CONTRACT_CLOSE_ONE (ZCON_CLOSE1) | contract |
| `releaseContract` | ZSOL_CONTRACT_RELEASE (ZCOREL) | contract |
| `updatePendingRate` | ZSD_RPT_PCONTRACT_REG_PCON (ZCON02) | contract |
| `closeSalesOrder` | ZSOL_SALESORDER_CLOSE (ZSOCLOSE) | order |
| `closeOrderProgram` | ZSOL_SO_CLOSE (ZSOCLOSE1) | order |

Static actions take the document id, so both adaptations
([`manage-sales-contracts-ext`](../../apps/manage-sales-contracts-ext) and
[`manage-sales-orders-ext`](../../apps/manage-sales-orders-ext)) call them by id —
they both point at `REPLACE_WITH_SALESDOC_STATUS_SERVICE`. Each action drives the
standard sales document via `BAPI_SD_SALESDOCUMENT_CHANGE` (TODO); no standard
object is modified.

## Objects in `src/`
`ZI_SalesDocStatus` (VBAK read) · `ZC_SalesDocStatus` (projection) · behavior
(6 static actions) · `zbp_i_sales_doc_status` (handlers, BAPI TODO) · param/result
abstract entities (`ZD_ContractAction` / `ZD_PendingRate` / `ZD_ContractResult` /
`ZD_OrderAction` / `ZD_OrderResult`) · service def `ZUI_SALESDOC_STATUS`.

## Create in ADT
- OData V4 service binding `ZUI_SALESDOC_STATUS_O4`.

## Branch
Tracked on `claude/fiori-app-extensions-h1nb64`.
