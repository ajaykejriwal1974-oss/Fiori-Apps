# BI layer — consolidation analysis (87 reports → ~30)

The **87 `BI` tcodes** are reports. Many are **create/change/display/delete
variants, division copies, "new"/"old" versions, or literal copies of the same
report** — they collapse hard. The target: re-platform as a **small set of CDS
analytical queries** (Embedded Analytics / the external BI layer), parameterised
by the dimension that used to be a separate tcode.

> Rule of thumb: a report family becomes **one** analytical CDS query with the
> distinguishing factor (division, create/display, batch/box/size) as a
> **filter/parameter or a drill-down dimension** — not a separate program.

## A. Dead / non-used — drop outright (≈8)
| Z tcode | Why |
|---|---|
| `ZASTOCK` | program `Z_MATERIAL_LEDGER`, description *"zastock(**ztest**)"* — a test/scratch report |
| `ZPCON_CP` | program `..._N_COPY`, description *"copy of pcon"* — a literal copy of `ZPCON` |
| `ZFI007T` | `..._VEND_AGEING_T` — temp/test duplicate of `ZFI007` (vendor ageing) |
| `ZPLIST02N` / `ZPLIST03N` | `..._N` duplicate skins of the packing list (see family C) |
| `ZRG1` / `ZRG1N` / `ZRG1TEX` | **RG1 excise register — pre-GST, obsolete** under GST (see F) |

> Confirm last-run dates in `STAD`/`ST03`/the job log before deleting; "no runs in
> 12 months" + a duplicate program = safe to retire.

## B. Already covered elsewhere — don't rebuild as a report (≈5)
| Z tcode | Covered by |
|---|---|
| `ZMTOS` | transactional **`backend/mtos-process-rap`** (the report is its worklist) |
| `ZMC46` (slow-moving) | analytics layer already (was routed in ROUTE7-PLAN) |
| `ZRECPM` (recipe report) | the **Recipe Master** app (`backend/recipe-master-rap`) — add a query |
| `ZJOBREPORT` (old job card) | superseded by `ZJOBREPTN`; both feed the **Job Master** app |
| `ZTASKLIST` | task-list **create** utility (`STC01`-style), not a report |

## C. Packing-list family — 17 → 2  ⭐ biggest win
All are Create/Change/Display/Delete × division (standard / `IPL` / `HSM` / `N`)
of the **same** packing list (programs `ZSD_PACKING_LIST_01` / `_IPL` / `_HSM` /
`_N`, plus `ZSD_PACKING_REPORT`, `ZSALES_DOC_POST(_01)`).

`ZPLIST01/01A/01T/02/02N/02T/03/03N/03T/D/DA/DT`, `ZPACKLIST`, `ZPACKLIST01`,
`ZPACKLISTN`

→ **(1)** a *Packing List* worklist (the create/maintain side already exists as
`apps/dyeing-packing` + `backend/packing-detail-rap`), and **(2)** one *Packing
Register* analytical query over `ZPP_PACK` ⋈ delivery, with **division** and
**create/display** as filters. **15 retired.**

## D. Sales register family — 5 → 1 (+ broadcast)
`ZSALES` (`ZCRPT_SD_001`), `ZSALESN` (`ZSD_SALES_RPT_NEW`), `ZSALESB`
(batch-wise), `ZSALESMAIL` (auto-email), `ZSOREG` (order register).

→ **one Sales Register** analytical query with **batch-level drill-down** (covers
`ZSALESB`) and an **order vs invoice** parameter (covers `ZSOREG`). `ZSALESMAIL`
is the *same* query on a **scheduled email broadcast**, not a separate report.
**4 retired.**

## E. Packed-stock dimension family — 8 → 1
Same packed-box stock (`ZPP_PACK` + grade/shade/size/end), sliced differently:
`ZBOXSTOCK` (box), `ZGSTOCK` (grade), `ZPRP1` (grade %), `ZSSTOCK` (size),
`ZDSTOCK` (dyeing), `ZSTOCK` (summary), `ZPRP` (packed boxes), `ZPRPSZ` (size-wise).

→ **one Packed-Stock Analysis** query with **box / grade / shade / size / dyeing**
as drill-down dimensions and a % measure. **7 retired.**

## F. Statutory FI/excise — combine or retire under GST (≈12)
| Family | Members | Target |
|---|---|---|
| GST tax report | `ZGST`, `ZGST1`, `ZGST2`, `ZGSTCR` (all over `ZSOL_GST_DET`) | **1** query; or standard **GST returns / DRC**. 3 retired |
| RG1 excise register | `ZRG1`, `ZRG1N`, `ZRG1TEX` | **Retire** — pre-GST excise, replaced by GST/DRC |
| Purchase register | `ZPUREG`, `ZPR` (purchase req), `ZF201B` (PRT) | **1** purchase register (GSTR-2 aligned) |
| Export incentive | `ZGCUDB` (DEPB), `ZBRC`/`ZEXP` (PRT) | **1** export-incentive register |
| Credit/Debit note | `ZCDQD`, `ZCRDRPN` | **1** |

## G. Finance receivables/payables — combine, prefer standard (≈13)
| Family | Members | Target |
|---|---|---|
| Ageing | `ZFI005` (customer), `ZFICAG` (debtors as-on-date), `ZFI007` (vendor), ~~`ZFI007T`~~ | **Customer/Supplier Ageing** standard apps, or **1** parameterised query. 4→1–2 |
| Account statement | `ZFICSR` (customer), `ZFIGSR` (G/L), `ZFIVSR` (vendor) | standard **Statement** apps, or **1** by account type. 3→1 |
| Interest | `ZFINT`, `ZFINT1` (both "Interest Report") | **1**. 1 retired |
| TDS | `ZFI_TDS` (vendor+customer), `ZQTDS` (quarterly) | **1** with a period parameter. 1 retired |
| Commission | `ZCOMM` | keep (1) |

## H. Generic stock — route to STANDARD (≈4)
`ZMB5B` (stock summary → **MB5B** / *Stock – Multiple Materials*), `ZCMM001`
(MM stock → *Material Documents Overview*), `ZBSTOCK` (batch-wise → standard batch
stock), ~~`ZASTOCK`~~ (junk). **Use standard inventory apps — build nothing.**

## I. PP / HU / dispatch — combine (≈10)
| Family | Members | Target |
|---|---|---|
| Job card report | `ZJOBREPTN` (+ retired `ZJOBREPORT`) | **1**, off the Job Master |
| HU analytics | `ZHUMO` (monitor), `ZHUREC` (reconciliation), `ZHUINV_CLS` (HU inventory) | **1** HU analysis query. 2 retired |
| Dispatch | `ZPWDIS` (schedule-wise), `ZDISPATCH` (security), `ZPDESP` (pending dispatch), `ZSCAND` (download) | **1–2** dispatch queries |
| Pending contract | `ZPCON`/`ZPCOND`/`ZPCONS` (+ retired `ZPCON_CP`) | **1** with register/schedule/header as a view parameter. 3 retired |
| WIP | `ZBATCH_WIP` | keep (1) |
| PO close | `ZPOCLOSE`, `ZPO_CLOSE` | **1** (really an action — see EXT). 1 retired |

## J. Remaining singletons — keep as individual queries (≈10)
`ZAUDIT_LOG`, `ZCRP` (returnable packaging), `ZCSD001` (unassign return boxes),
`ZCUST` (customer master ALV), `ZJWCHLN` (job-work challan), `ZPEL` (pallet),
`ZRFQ` (RFQ), `ZINVC_DS` (invoice w/ digital sign — partly a PRT form),
`ZACTUAL` (std-vs-actual cost), `ZHUINV_CLS`.

## Net result
| | Reports |
|---|---:|
| Start | **87** |
| Drop dead/duplicate (A) | −8 |
| Already covered (B) | −5 |
| Packing-list family (C) | −15 |
| Sales register (D) | −4 |
| Packed-stock (E) | −7 |
| Statutory/excise (F) | −7 |
| FI receivables/payables (G) | −7 |
| Generic stock → standard (H) | −4 |
| PP/HU/dispatch (I) | −9 |
| **Target** | **≈ 31** |

**≈ 87 → ~31 (≈ 64% fewer)** — roughly **20 custom CDS analytical queries** +
**~8 routed to standard inventory/AR/AP apps** + **GST/excise retired to DRC**.
Each surviving query carries the old variants as **parameters/dimensions**, so no
functional coverage is lost.

## ✅ Built — 11 consolidated analytical queries
The custom survivors are built as CDS cube+query pairs in
[`backend/analytics`](../backend/analytics) (read-only, dimensions = old
variants): `ZC_PackedStockQuery`, `ZC_PackingRegisterQuery`, `ZC_WipBatchQuery`,
`ZC_HuInventoryQuery`, `ZC_PendingContractQuery`, `ZC_ExportRegisterQuery`,
`ZC_MergeAnalysisQuery`, `ZC_RecipeAnalysisQuery`, `ZC_JobCardQuery`,
`ZC_DispatchRegisterQuery`, `ZC_GstTaxQuery`, plus two sibling queries on
existing cubes — `ZC_HuMonitorQuery` (monitor/reconciliation) and
`ZC_PendingDispatchQuery` (pending/security gate). These 13 replace ~40 of the BI
reports; the remainder are dropped, routed to standard, or covered by built apps.

## Method to confirm before cutting
1. **Usage** — pull `ST03N`/`STAD` last-run + frequency per tcode; anything with
   0 runs in 12 months and a duplicate program is a safe drop.
2. **Field parity** — diff the ALV field catalogs of a family; if identical bar a
   filter, they merge.
3. **Build** — author the consolidated CDS query (analytical), expose via a
   *Design Studio*/*Analytical List Page* or the external BI tool; map the old
   tcode users to the new query + role.
4. **Retire** — remove the Z reports after a parallel run.
