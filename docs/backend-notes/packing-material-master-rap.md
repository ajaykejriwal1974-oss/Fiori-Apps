# Packing Material Master (ZPACK_MAST) — managed RAP over `ZPACK_MAST`

Custom master (KEJRIWAL Z-portfolio, `CUS`). Built as a **managed RAP**
business object **mapped onto the existing legacy table `ZPACK_MAST`** —
no new persistence is created. The Fiori Elements *Manage* app is generated
from the service binding via the metadata extension `zc_packing_material.ddlx`.

> **Fields are refit to the real Z-table** (from the field dictionary):
> data elements, types, lengths and the key mirror the legacy table.
> **Value helps** (standard `I_*StdVH`; shade fields → the Shade master
> `ZC_DD_Shade`) and **in-table text** are wired on the projection/interface —
> VERIFY the released VH names per release before activating.

## Fields (from the field dictionary)

| CDS element | Table column | Key |
|---|---|:--:|
| `PackingType` | `PTYPE` | 🔑 |
| `WorkCenter` | `ARBPL` | 🔑 |
| `Material` | `MATNR` | 🔑 |
| `StorageLocation` | `LGORT` |  |
| `Batch` | `CHARG` |  |
| `Sequence` | `SEQ` |  |

## Objects in `src/`

| File | Object | Role |
|---|---|---|
| `zi_packing_material.ddls.asddls` | `ZI_PackingMaterial` | Interface CDS over `zpack_mast` |
| `zc_packing_material.ddls.asddls` | `ZC_PackingMaterial` | Projection (`transactional_query`) |
| `zi_packing_material.bdef.asbdef` | Behavior (managed) | create/update/delete, mapping |
| `zc_packing_material.bdef.asbdef` | Projection behavior | use create/update/delete |
| `zbp_i_packing_material.clas.*` | Behavior pool | `setDefaults` + `validateKey` |
| `zc_packing_material.ddlx.asddlxs` | Metadata ext | Fiori Elements List Report / Object Page |
| `zui_packing_material.srvd.srvdsrv` | Service def `ZUI_PACKING_MATERIAL` | exposes `ZC_PackingMaterial` |

## Create in ADT
- The table `ZPACK_MAST` **already exists** — the managed BO binds to it
  as `persistent table zpack_mast`. No DDIC table to create.
- Key: `PTYPE`, `ARBPL`, `MATNR`.
- This legacy table has **no TIMESTAMPL column**, so the optimistic-
  concurrency ETag is omitted; `lock master` still applies. Add a
  TIMESTAMPL column if optimistic locking is required.
- Create the OData V4 UI service binding `ZUI_PACKING_MATERIAL_O4` in ADT.

## Branch
Tracked on `claude/fiori-app-extensions-h1nb64`.
