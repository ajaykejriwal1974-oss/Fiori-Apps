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
| `ZI_ACCGRP` / `ZC_ACCGRP` behavior | managed (class-free) + projection behavior |
| `ZC_ACCGRP` / `ZC_ACCGRP_ACC` metadata ext | UI annotations |
| `ZUI_ACCGRP` | service definition |
| `ZUI_ACCGRP_04` | OData V4 UI service binding (publish via /IWFND/V4_ADMIN) |

**9 objects, no ABAP class** — same class-free shape as the 13 master-data BOs.

## Design notes
- **Managed, non-draft, CLASS-FREE.** The BO has no determinations/validations/actions,
  so `managed;` needs no behavior class. The legacy tables have no admin/ETag columns,
  so there is no `etag master` and no audit fields — concurrency is handled by the
  pessimistic `lock master`. This avoids any DDIC change to live data. See
  [`src/tables.spec.md`](src/tables.spec.md).
- `ZSOL_PRDPLAN` (Daily Production Plan) is intentionally excluded — separate object.

## Deploy — via abapGit (same as the master-data fleet)
The 9 objects are staged in [`backend/_abapgit_import/src/`](../_abapgit_import) (source
+ abapGit `.xml` wrappers), so they come in with the existing repo pull — no raw ADT
REST needed.
1. **abapGit → Pull** the repo (branch `claude/fiori-apps-ui5-completeness-4bvlmp`) into
   package `ZKGPL_FIORI`. abapGit resolves order and activates (interface → projection →
   metadata ext → behavior). Pull/activate twice if a first pass leaves any inactive.
2. Create OData V4 service binding `ZUI_ACCGRP_04` on `ZUI_ACCGRP` (ADT → New Service
   Binding → OData V4 - UI → Activate), then **publish** (via `/IWFND/V4_ADMIN` →
   Publish Service Groups if Eclipse local publish is blocked by client role).
3. Deploy the FE app [`apps/account-grouping`](../../apps/account-grouping) and add the
   FLP tile (semantic object `AccountGroup`, action `manage`).

Status: **LIVE on KSD (client 500), 23 Jul 2026.** Pulled via abapGit, activated
(behaviors made class-free/non-strict, no authorization — see below), `ZUI_ACCGRP_04`
published via `/IWFND/V4_ADMIN`, FE app deployed and rendering 91 groups from
`ZSOL_ACCGRP` in the FLP.

> **Activation notes (KSD):** the behaviors are `managed;` with **no `strict`** (the
> composition child tripped a strict(2) rule) and **no `authorization`** (instance
> auth needs a behavior class; this BO is class-free). This matches the other
> class-free masters (e.g. `ZI_RECIPE`).
