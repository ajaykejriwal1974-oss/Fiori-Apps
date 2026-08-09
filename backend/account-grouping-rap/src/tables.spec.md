# Persistence — EXISTING legacy tables (do NOT create)

Unlike the greenfield masters (e.g. `zdd_shade`), this BO maps to **two tables that
already exist on KSD** — the managed BO wraps them, no DDIC creation needed.

## `ZSOL_ACCGRP` — "Solsynch: Account Group Master" (root persistence)
| Field | Key | Type | BO field |
|---|---|---|---|
| `MANDT`     | ✔ | CLNT 3   | (client, implicit) |
| `ZZSOL_GRP` | ✔ | CHAR 8   | `GroupCode` |
| `TEXT50`    |   | CHAR 50  | `GroupText` |
| `ZSIGN_REV` |   | INT4     | `SignReversal` |

## `ZSOL_ACC_GRP` — "Solsynch: Account Grouping for MIS" (child persistence)
| Field | Key | Type | BO field |
|---|---|---|---|
| `MANDT`     | ✔ | CLNT 3  | (client, implicit) |
| `RACCT`     | ✔ | CHAR 10 | `GLAccount` |
| `ZZSOL_GRP` |   | CHAR 8  | `GroupCode` (parent link) |

Notes:
- Physical PK of the child is `MANDT + RACCT` (a G/L account belongs to exactly one
  group). The BO key is modelled as `(GroupCode, GLAccount)` so the managed
  composition auto-fills `GroupCode` from the parent on child create; uniqueness is
  still enforced by the DB PK on `RACCT`.
- No admin/ETag columns exist on either table → managed **non-draft**, `lock master`
  only (no `etag master`). This is intentional — no schema change to live data.
- `ZSOL_PRDPLAN` ("Daily Master Production Plan") is also touched by the legacy
  program but is a **separate MIS object** (plant/work-centre/date production
  targets), NOT part of the Account Grouping master. Out of scope here.
