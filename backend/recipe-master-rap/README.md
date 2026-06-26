# Dyeing Recipe Master (Route 7 custom master) - managed RAP

Custom master with **no standard SAP equivalent** (KEJRIWAL Z-portfolio, Route 7).
Built as a **managed RAP** business object - same pattern as `backend/shade-master-rap`
(framework owns the custom table). The Fiori Elements "Manage Dyeing Recipe Master" app is
generated from the service binding via the metadata extension `zc_recipe.ddlx`.

> **Skeleton.** The field list is a best-effort starting point - **VERIFY it
> against the original Z program** (and confirm there is truly no standard app in
> the Fiori Apps Reference Library) before building.

## Objects in `src/`
| File | Object | Role |
|---|---|---|
| `zi_recipe.ddls.asddls` | `ZI_Recipe` | Interface CDS over `zrecipe` |
| `zc_recipe.ddls.asddls` | `ZC_Recipe` | Projection (`transactional_query`) |
| `zi_recipe.bdef.asbdef` | Behavior (managed) | create/update/delete, ETag, mapping |
| `zc_recipe.bdef.asbdef` | Projection behavior | use create/update/delete |
| `zbp_i_recipe.clas.abap` + `.locals_imp` | Behavior pool | `setDefaults` + `validateKey` |
| `zc_recipe.ddlx.asddlxs` | Metadata ext | Fiori Elements List Report / Object Page |
| `zui_recipe.srvd.srvdsrv` | Service def `ZUI_RECIPE` | exposes `ZC_Recipe` as `Recipe` |

## Create in ADT
- DB table `zrecipe` (spec below) + service binding `ZUI_RECIPE_O4` (OData V4 - UI).

### Table `zrecipe` (DDIC)
| `recipe_code` (key, char10), `recipe_name` char40, `shade_code` char10 (→ ZDD_SHADE value help), `process_type` char20, `temperature` dec(5,1), `duration_min` int4, `is_active` abap_boolean |
- Admin fields: `created_by abp_creation_user`, `created_at abp_creation_tstmpl`,
  `last_changed_by abp_lastchange_user`, `last_changed_at abp_lastchange_tstmpl`,
  `local_last_changed_at abp_locinst_lastchange_tstmpl`.

## Branch
Developed on `claude/fiori-app-extensions-h1nb64`.
