# Functional check — does *Post Goods Movement (HU)* actually replace `ZVLMOVE`?

**Date:** 2026-08-19
**Verdict:** **Not yet — same intent, different mechanics.** The gap is real but
small; it is a handler change, not a new app.

`docs/UPL-MIGRATION.md` §G lists `ZVLMOVE` (`ZSOL_VLMOVE_BAPI`) as *"already
covered by `backend-notes/goods-movement-hu-rap.md`"*. Reading the code that
actually shipped shows that claim is **too strong**. This note records the
difference, the risk, and the test that settles it.

---

## What each side does

### `ZVLMOVE` (`ZSOL_VLMOVE_BAPI`, references `ZZMARA`)

A Z wrapper around standard **`VLMOVE` — Move Handling Units**. The unit of work
is the **handling unit itself**: the HU is relocated (storage location, and
optionally plant), the HU header is updated, and the material document is posted
*with the HU reference*. Stock inside the HU stays packed. `ZZMARA` in the
program's table list means selection is driven by the Kejriwal material
extension fields (product type / denier / filament).

### `apps/post-goods-movement-hu` → `ZI_HU_ITEM` / `postGoodsMovement`

From `backend/src/zbp_i_hu_item.clas.locals_imp.abap`, the shipped handler:

1. splits `HandlingUnitList` on `;`,
2. reads `VEKP` → `VENUM`, then **`VEPO` contents** (`MATNR`, `CHARG`, `VEMNG`, `VEMEH`),
3. builds `BAPI2017_GM_ITEM_CREATE` rows for those contents,
4. calls **`BAPI_GOODSMVT_CREATE`** with `GM_CODE = '04'` (transfer posting) and
   the movement type from the action header,
5. commits and returns the material document.

The HU is used **only as a way to find the materials**. Nothing in the call
carries the handling unit forward.

---

## The three concrete differences

| # | `ZVLMOVE` | Shipped app | Consequence |
| --- | --- | --- | --- |
| 1 | Moves the **HU** (`VEKP-LGORT` / `WERKS` updated, HU stays packed) | Moves the **contents**; `VEKP` untouched | After the post the stock sits in the new location but the HU record still points at the old one — the HU is stranded. In HU-managed storage locations the post is normally **rejected** outright. |
| 2 | Material document carries the **HU reference** | No HU fields populated in `BAPI2017_GM_ITEM_CREATE` | No HU history on the document; HU-based traceability and reprints break. |
| 3 | Selection driven by `ZZMARA` (product type / denier / filament) | HU numbers only, typed or scanned | Operators who select "all denier X in plant 2002" cannot reproduce that in the app. Overlaps with task #20 (extend `ZI_PACKED_STOCK`). |

Two smaller items worth noting while the handler is open:

- `ls_header-pstng_date` is hard-coded to `sy-datum` — no back-dating, whereas
  `VLMOVE` accepts a posting date.
- `GM_CODE` is fixed at `'04'` (transfer posting / MB1B). A plant-to-plant move
  or a 501/502 receipt would need a different code. The backend note already
  flags this as **VERIFY**.

---

## The test that settles it

Run on **KSD**, plant 2002, with one HU that has contents. Do it in this order —
step 2 is the one that decides the answer.

| # | Step | Expected if the app really replaces `ZVLMOVE` |
| --- | --- | --- |
| 1 | `HUMO` / `SE16N` on `VEKP` — note `VENUM`, `EXIDV`, `WERKS`, `LGORT` for the test HU | baseline recorded |
| 2 | Is the source storage location **HU-managed**? (`T001L`, or `LGORT` assigned to an HU-managed warehouse) | If **yes**, the app's post will fail with an HU-required message — replacement is impossible without the HU reference |
| 3 | Run the app: scan the HU, movement type 311, from/to storage location, Post | material document number returned |
| 4 | Re-read `VEKP` for the same `VENUM` | `ZVLMOVE` would show the **new** `LGORT`. The app will show the **old** one → confirms difference #1 |
| 5 | `MB51` / `MSEG` on the material document — check `EXIDV` / HU fields | `ZVLMOVE` populates them; the app will not → confirms #2 |
| 6 | Repeat 1–5 with `ZVLMOVE` on a comparable HU and diff the two material documents | the diff is the exact work list |

Record the outcome of step 2 first. It is the fork:

- **HU-managed location → the app cannot be used as-is.** The handler must call
  the HU move path, not `BAPI_GOODSMVT_CREATE` on contents.
- **Not HU-managed → the app posts, but leaves the HU stale.** Still needs
  fixing before it replaces `ZVLMOVE`, but it can go live for non-HU-managed
  moves in the meantime.

---

## Recommended fix (when the test confirms the above)

Change the handler in `zbp_i_hu_item.clas.locals_imp.abap` — the CDS views, the
service, the binding and the whole UI5 app stay as they are.

1. Replace the `VEPO` → `BAPI_GOODSMVT_CREATE` loop with the HU move path:
   **`HU_POST_GOODS_MOVEMENT`** / `BAPI_HU_...` (or `WS_DELIVERY_UPDATE` where the
   move is delivery-driven, which is what `VLMOVE` does for outbound HUs).
   Verify the exact function module available in this release in ADT before
   coding — do not assume.
2. Add `PostingDate` to `ZD_HU_POST_MOVEMENT` (blank → `sy-datum`), mirroring the
   pattern now used by `ZD_CONF_CANCEL`.
3. Make `GM_CODE` a parameter rather than the literal `'04'`, or derive it from
   the movement type.
4. Keep the existing `BAPI_GOODSMVT_CREATE` branch for non-HU-managed moves if
   the plant genuinely uses both.
5. Add the `ZZMARA` selection fields to the read view so the `ZVLMOVE`-style
   "all denier X" selection is reproducible (shares work with task #20).

Effort: one behaviour-pool method plus one abstract-entity field. No new
objects, no new transport of UI content.

---

## Documentation to correct

`docs/UPL-MIGRATION.md` §G currently reads:

> `ZVLMOVE` (`ZSOL_VLMOVE_BAPI`) | goods-movement/delivery move — covered by **`backend-notes/goods-movement-hu-rap.md`**

Change "covered by" to "**partially** covered by … — see
`ZVLMOVE-vs-POST-GOODS-MOVEMENT-HU.md`" once the test above is run, so the
migration count (28 → ≈11) is not overstated.
