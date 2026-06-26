# Post Packing & GR (Route 7) - unmanaged RAP service (skeleton)

Custom transactional service for **Post Packing & GR** (posting packing and GR, replaces ZPOST01). Unmanaged RAP over
standard SAP (same family as the packing app / `backend/goods-movement-hu-rap`):
a read model + static action(s) calling standard BAPIs.

> **Skeleton.** Read source (`vekp`) + BAPI calls are best-effort -
> **VERIFY against your release and the original Z program** before activating.


## Actions — GR wired ✅
| Action | Implementation | Purpose |
|---|---|---|
| `postPackingAndGr` | reads HU contents (VEPO⋈VEKP) → `BAPI_GOODSMVT_CREATE` (gm_code `01`) | Post goods receipt for the selected HUs |

> The GR is wired; if the HUs still need **packing** first, add the `BAPI_HU_PACK`
> call before the GR. VERIFY `gm_code`/movement type for your GR scenario.

## Objects in `src/`
Read CDS `ZI_PostPackGr` / projection `ZC_PostPackGr`, abstract import + result entities per
action, unmanaged behavior + projection behavior, behavior class `zbp_i_post_packing_gr`
(BAPI TODO), service def `ZUI_POST_PACK_GR`. Create the V4 binding `ZUI_POST_PACK_GR_O4` in ADT.

## Branch
Developed on `claude/fiori-app-extensions-h1nb64`.
