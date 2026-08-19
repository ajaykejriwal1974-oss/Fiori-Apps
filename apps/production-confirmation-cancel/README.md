# Cancel Production Confirmation

Bulk cancellation (reversal) of production order confirmations.

Closes gap #1 from `docs/fiori-gap-analysis-2026-08-19.md`: the plant reverses
confirmations one at a time in **CORS**, with no way to select a day's postings
and reverse them together.

## What it does

- Filter-first worklist over `AFRU` (company code, plant, order, operation,
  material, posting-date range, created-by; "Hide cancelled" on by default).
- Multi-select rows → **Cancel Confirmations** → confirmation prompt → optional
  posting date → one RAP action reverses them all.
- Quick search, sort, Excel export.

The list shows **original** confirmations only. Reversal documents themselves
(`AFRU-STOKZ = 'X'`) are filtered out in the CDS view; rows already cancelled
(`AFRU-STZHL <> 0`) are flagged and skipped both client-side and in the handler.

## Backend objects (`backend/src`, package `ZKGPL_FIORI`)

| Object | Type | Purpose |
| --- | --- | --- |
| `ZI_PROD_CONFIRMATION` | DDLS | Root view: AFRU + AFKO + T001K (company code via valuation area) |
| `ZC_PROD_CONFIRMATION` | DDLS | Projection, `provider contract transactional_query` |
| `ZD_CONF_CANCEL` | DDLS | Abstract entity — action import parameter |
| `ZD_CONF_CANCEL_RESULT` | DDLS | Abstract entity — action result |
| `ZI_PROD_CONFIRMATION` | BDEF | Unmanaged, `static action cancelConfirmations` |
| `ZC_PROD_CONFIRMATION` | BDEF | Projection, `use action cancelConfirmations` |
| `ZBP_I_PROD_CONFIRMATION` | CLAS | Behaviour pool — calls `BAPI_PRODORDCONF_CANCEL` |
| `ZUI_PROD_CONFIRMATION` | SRVD | Service definition (+ 4 value-help entity sets) |
| `ZUI_PROD_CONFIRM_04` | SRVB | OData V4 binding |

Service URI: `/sap/opu/odata4/sap/zui_prod_confirm_04/srvd/sap/zui_prod_confirmation/0001/`

### Action contract

`cancelConfirmations` is a **static** action with a flat parameter pair:

```
PostingDate      : abap.dats    " blank -> sy-datum on the server
ConfirmationList : abap.char(1333)   " 'RUECK=RMZHL;RUECK=RMZHL;...'
```

This matches the pattern already live in `ZI_HU_UNPACK` (flat delimited string,
not an `_Item` composition). Note that the shipped `hu-unpack` controller sends
`_Item` while the live BDEF takes the flat string — the two disagree. This app
is built to the flat contract, i.e. to what actually deploys.

`BAPI_PRODORDCONF_CANCEL` is an update-task BAPI, so it is called
`DESTINATION 'NONE'` to get its own LUW, and both `RETURN` and `DETAIL_RETURN`
are checked before `BAPI_TRANSACTION_COMMIT`.

## Deploy

1. abapGit pull in `ZABAPGIT` on KSD, then activate in Eclipse (ADT).
2. Publish the service binding `ZUI_PROD_CONFIRM_04`.
3. Confirm `SERVICE_NS` in `webapp/controller/Worklist.controller.js` matches
   the action namespace in `/$metadata` (expected
   `com.sap.gateway.srvd.zui_prod_confirmation.v0001`).
4. `npm install && npm run deploy` — BSP application `ZPROD_CONF_CAN`.
5. Add the tile to the **Production** space; semantic object
   `ProdConfirmation`, action `cancelKejriwal`.

## Authorisations

The handler calls the standard BAPI, so the caller needs the usual
`C_AFRU_AWK` / `C_AFRU_AWA` confirmation-reversal authorisations. It does not
bypass any standard check.
