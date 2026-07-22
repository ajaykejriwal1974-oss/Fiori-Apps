# packing-list-rap — Packing List backend (RAP, unmanaged)

Clean-core replacement backend for the **ZPLIST family** (14 transactions over
programs `ZSD_PACKING_LIST_01 / _IPL / _HSM / _N`). One read model + three static
actions replace create/change/display/delete across all plant/format variants.

## Objects
| Object | Type | Purpose |
|---|---|---|
| `ZI_PACKING_LIST` | root view entity | read model: `ZSOL_HUDISPATCH` ⟕ `ZPP_PACK` ⟕ `ZVBAP` |
| `ZC_PACKING_LIST` | projection | transactional_query, searchable |
| `ZI/ZC_PACKING_LIST` bdef | behavior | 3 static actions (unmanaged, `zbp_i_packing_list`) |
| `ZD_PACKING_LIST_IMPORT` | abstract entity | flat action import (`BoxList` = `BOX1;BOX2;…`) |
| `ZD_PACKING_LIST_RESULT` | abstract entity | `{BoxesAffected, PackListItem, Message}` |
| `ZUI_PACKING_LIST` | service definition | exposes `PackingList` |
| `zbp_i_packing_list` | behavior pool | action stubs with TODO/VERIFY markers |

## VERIFY before activating (same drill as dispatch-correction-rap)
1. `ZPP_PACK` join — table is keyed `BOXNO + GJAHR`; add the year predicate or a
   "latest year" rule to the `ZI_PACKING_LIST` join.
2. Pack-list numbering — per sales order or per item? Mirror `ZSD_PACKING_LIST_01`.
3. `ZPLISTD` soft-delete key (`VBELN, POSNR, PKLST, BOXNO`) and audit fields.
4. Whether a box may move between pack lists in *change* mode.

## Activation order
CDS interface → abstract entities → projection → bdefs → behavior pool →
service definition → **service binding `ZUI_PACKING_LIST_04` (OData V4 UI)** →
publish. Package `ZKGPL_FIORI` (align with TRANSPORT-PLAN.md).

## Retires
The 14 `ZPLIST*` transactions (see the app README). Uses existing tables only —
no new Z-tables.
