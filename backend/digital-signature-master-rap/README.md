# Digital Signature (Route 7 custom master) - managed RAP

Custom master with **no standard SAP equivalent** (KEJRIWAL Z-portfolio, Route 7).
Built as **managed RAP** - same pattern as `backend/shade-master-rap`. The Fiori
Elements "Manage Digital Signature" app is generated from the service binding via the
metadata extension `zc_digital-signature.ddlx`.

> Confirm this is a business signatory master, NOT a Basis/security digital-signature setting.

> **Skeleton.** The field list is a best-effort starting point - **VERIFY it
> against the original Z program** and confirm there is no standard app in the
> Fiori Apps Reference Library before building.

## Objects in `src/`
| File | Object | Role |
|---|---|---|
| `zi_digital-signature.ddls.asddls` | `ZI_DigSign` | Interface CDS over `zdigsign` |
| `zc_digital-signature.ddls.asddls` | `ZC_DigSign` | Projection (`transactional_query`) |
| `zi_digital-signature.bdef.asbdef` | Behavior (managed) | create/update/delete, ETag, mapping |
| `zc_digital-signature.bdef.asbdef` | Projection behavior | use create/update/delete |
| `zbp_i_digital-signature.clas.*` | Behavior pool | `setDefaults` + `validateKey` |
| `zc_digital-signature.ddlx.asddlxs` | Metadata ext | Fiori Elements List Report / Object Page |
| `zui_digital-signature.srvd.srvdsrv` | Service def `ZUI_DIGSIGN` | exposes `ZC_DigSign` |

## Create in ADT
- DB table `zdigsign`: `signatory_id` (key char10), `signatory_name` char40, `designation` char30, `valid_from` dats, `valid_to` dats, `is_active` abap_boolean
- Admin fields: `abp_creation_user/tstmpl`, `abp_lastchange_user/tstmpl`, `abp_locinst_lastchange_tstmpl`.
- Service binding `ZUI_DIGSIGN_O4` (OData V4 - UI).

## Branch
Developed on `claude/fiori-app-extensions-h1nb64`.
