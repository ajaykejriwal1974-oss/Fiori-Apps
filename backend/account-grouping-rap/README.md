# Account Grouping master (ZSOL_ACCGRP) — managed RAP backend

Clean-core Fiori replacement for transaction **`ZSOL_ACCGRP`** ("Maintain Account
Grouping", program `SAPLZSOL_DASH`). Genuine custom master — it has real Z-tables,
so unlike ZMINMAX / ZBOE it **is** rebuilt (not routed to standard).

Maintain **account groups** and the **G/L accounts assigned to each group** (used for
MIS / financial statement grouping; the `SignReversal` flag flips the sign of a
group's balance in reports).

## Object model — composition
```
AccountGroup (root, ZSOL_ACCGRP)  ──_Accounts──▶  AccountAssignment (child, ZSOL_ACC_GRP)
  GroupCode  (ZZSOL_GRP)                             GroupCode (ZZSOL_GRP, parent link)
  GroupText  (TEXT50)                                GLAccount (RACCT)
  SignReversal (ZSIGN_REV)
```
Fiori Elements renders it as a List Report of groups → Object Page with a table of
assigned G/L accounts you can add / remove.

## Objects (package ZKGPL_FIORI)
| Object | Type |
|---|---|
| `ZI_ACCGRP` / `ZI_ACCGRP_ACC` | CDS interface root + composition child |
| `ZC_ACCGRP` / `ZC_ACCGRP_ACC` | CDS projections |
| `ZI_ACCGRP` behavior + `ZBP_I_ACCGRP` | managed behavior + (empty) pool class |
| `ZC_ACCGRP` behavior | projection behavior |
| `ZC_ACCGRP` / `ZC_ACCGRP_ACC` metadata ext | UI annotations |
| `ZUI_ACCGRP` | service definition |
| `ZUI_ACCGRP_04` | OData V4 UI service binding (publish via /IWFND/V4_ADMIN) |

## Design notes
- **Managed, non-draft.** The legacy tables have no admin/ETag columns, so there is
  no `etag master` and no audit fields — concurrency is handled by the pessimistic
  `lock master`. This avoids any DDIC change to live data. See [`src/tables.spec.md`](src/tables.spec.md).
- **No behavior-class logic.** Pure managed CRUD; `ZBP_I_ACCGRP` is an empty abstract
  pool (no determinations/validations/actions).
- `ZSOL_PRDPLAN` (Daily Production Plan) is intentionally excluded — separate object.

## Deploy (ADT, package ZKGPL_FIORI, client 500)
1. Create the 4 DDLS, 2 DDLX, 2 BDEF, 1 class, 1 SRVD in ADT (or import this src/).
2. Activate in dependency order: interfaces → projections → behaviors → class → service def.
3. Create OData V4 service binding `ZUI_ACCGRP_04` on `ZUI_ACCGRP`, **publish via
   `/IWFND/V4_ADMIN` → Publish Service Groups** (client 500 is Customizing-role, so
   Eclipse local publish is blocked — same as packing-list).
4. Bind the FE app [`apps/account-grouping`](../../apps/account-grouping) and add the
   FLP tile (semantic object `AccountGroup`, action `manage`).

Status: **scaffolded, not yet deployed.**
