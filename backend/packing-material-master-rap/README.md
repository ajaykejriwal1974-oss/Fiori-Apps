# Packing Material Master (Route 7 custom master) - managed RAP

Custom master with **no standard SAP equivalent** (KEJRIWAL Z-portfolio, Route 7).
Built as **managed RAP** - same pattern as `backend/shade-master-rap`. The Fiori
Elements "Manage Packing Material Master" app is generated from the service binding via the
metadata extension `zc_packing-material.ddlx`.

> **Skeleton.** The field list is a best-effort starting point - **VERIFY it
> against the original Z program** and confirm there is no standard app in the
> Fiori Apps Reference Library before building.

## Objects in `src/`
| File | Object | Role |
|---|---|---|
| `zi_packing-material.ddls.asddls` | `ZI_PackMaterial` | Interface CDS over `zpackmat` |
| `zc_packing-material.ddls.asddls` | `ZC_PackMaterial` | Projection (`transactional_query`) |
| `zi_packing-material.bdef.asbdef` | Behavior (managed) | create/update/delete, ETag, mapping |
| `zc_packing-material.bdef.asbdef` | Projection behavior | use create/update/delete |
| `zbp_i_packing-material.clas.*` | Behavior pool | `setDefaults` + `validateKey` |
| `zc_packing-material.ddlx.asddlxs` | Metadata ext | Fiori Elements List Report / Object Page |
| `zui_packing-material.srvd.srvdsrv` | Service def `ZUI_PACKMATERIAL` | exposes `ZC_PackMaterial` |

## Create in ADT
- DB table `zpackmat`: `packing_material` (key char18), `description` char40, `pack_type` char10 (Cone/Carton/Pallet), `tare_weight` quan(13,3), `weight_unit` unit(3), `is_active` abap_boolean
- Admin fields: `abp_creation_user/tstmpl`, `abp_lastchange_user/tstmpl`, `abp_locinst_lastchange_tstmpl`.
- Service binding `ZUI_PACKMATERIAL_O4` (OData V4 - UI).

## Branch
Developed on `claude/fiori-app-extensions-h1nb64`.
