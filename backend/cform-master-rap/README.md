# C-Form Allocation Master (ZCFORM1/ZFORM/ZFORMS/ZPCFORM) — managed RAP over `ZCFORM1`

Custom master (KEJRIWAL Z-portfolio, `CUS`). Built as a **managed RAP**
business object **mapped onto the existing legacy table `ZCFORM1`** —
no new persistence is created. The Fiori Elements *Manage* app is generated
from the service binding via the metadata extension `zc_cform.ddlx`.

> **Fields are refit to the real Z-table** (from the field dictionary):
> data elements, types, lengths and the key mirror the legacy table. Wire
> value helps (reuse `ZSOL_F4*`) and confirm before activating.

## Fields (from the field dictionary)

| CDS element | Table column | Key |
|---|---|:--:|
| `SalesOrganization` | `SALE_ORG` | 🔑 |
| `Customer` | `CUST_CODE` | 🔑 |
| `BillingDocument` | `INVOICE_NO` | 🔑 |
| `BillingDate` | `INVOICE_DT` |  |
| `InvoiceValue` | `INVOICE_VAL` |  |
| `FormType` | `FORM_TYPE` |  |
| `FormNumber` | `FORM_NO` |  |
| `FormDate` | `FORM_DT` |  |
| `AllocatedValue` | `ALLOCATED_VALUE` |  |
| `Quantity` | `QTY` |  |

## Objects in `src/`

| File | Object | Role |
|---|---|---|
| `zi_cform.ddls.asddls` | `ZI_Cform` | Interface CDS over `zcform1` |
| `zc_cform.ddls.asddls` | `ZC_Cform` | Projection (`transactional_query`) |
| `zi_cform.bdef.asbdef` | Behavior (managed) | create/update/delete, mapping |
| `zc_cform.bdef.asbdef` | Projection behavior | use create/update/delete |
| `zbp_i_cform.clas.*` | Behavior pool | `setDefaults` + `validateKey` |
| `zc_cform.ddlx.asddlxs` | Metadata ext | Fiori Elements List Report / Object Page |
| `zui_cform.srvd.srvdsrv` | Service def `ZUI_CFORM` | exposes `ZC_Cform` |

## Create in ADT
- The table `ZCFORM1` **already exists** — the managed BO binds to it
  as `persistent table zcform1`. No DDIC table to create.
- Key: `SALE_ORG`, `CUST_CODE`, `INVOICE_NO`.
- This legacy table has **no TIMESTAMPL column**, so the optimistic-
  concurrency ETag is omitted; `lock master` still applies. Add a
  TIMESTAMPL column if optimistic locking is required.
- Create the OData V4 UI service binding `ZUI_CFORM_O4` in ADT.

## Branch
Tracked on `claude/fiori-app-extensions-h1nb64`.
