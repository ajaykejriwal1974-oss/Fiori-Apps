# Tile upgrade — 30 Aug 2026

Nine tiles on `ZKIPL_CORRECTED_PG_PROD`, checked against the audit and against
`docs/KSQ_FLP_Corporate_Design.pdf`. Transport **KSDK906759**.

## Already active in KSD — nothing to do

| Object | Change |
|---|---|
| `ZI_WIP_BATCH` | deleted batches excluded; every dimension labelled |
| `ZI_SCHEDULE` | `ScheduleQty` re-linked to `SalesUnit` |

**The analytics cube was counting deleted batches.** No `DELIND` filter, so the
totals carried 91 deleted rows — 43,907.630 kg and 22,425 cheeses — alongside
the 131,502 live ones. A cube that quietly adds deleted rows to a quantity is
worse than a missing one, because the number still looks plausible.

**Two dimensions were both called "Material".** `GreyMaterial` and
`DyedMaterial` both resolve to `MATNR`, so the query browser showed "Material"
twice with nothing to tell them apart, plus "Assignment" and "batch close ind."
from the raw data elements. All dimensions now carry explicit labels.

**Schedule quantity was a bare number.** The `cast(...)` in `ZI_Schedule`
dropped the `@Semantics.quantity.unitOfMeasure` that `ZPP_SCHEDULEN` declares,
so the app showed a figure with the unit in a separate column and no link
between them.

## To activate in Eclipse

### 1. Label Master — one default printer per plant and type

The live bug. `IsDefault` had no uniqueness rule and plant 2002 has drifted:

```
type   printers   marked default
BLNK      14            3
KAS       14            1
KIL       14            9
MICR      14            1
```

Nine printers are default for KIL. Whatever asks for "the default printer" gets
whichever row the database returns first — so KIL labels are going to an
arbitrary printer today.

Two files: `zi_label_master.bdef.asbdef` adds a determination,
`zbp_i_label_master.clas.locals_imp.abap` implements it. Activate together.
Last one wins — saving a row as default clears the flag on the others in the
same plant and type. Refusing the save instead would leave the operator to hunt
down nine old defaults by hand.

**This does not clean up the existing rows.** The rule takes effect on the next
save. Someone who knows the shop floor has to say which of the nine KIL
printers and which of the three BLNK printers is correct; then either re-save
that row through the app, or clear the rest directly. I have not touched the
data.

### 2. Recipe Master — value help on Component Type

`zi_vh_comp_type.asddls` is a **new** Data Definition — create it in
`ZKGPL_FIORI`, then apply the one annotation in
`zc_recipe-componenttype-annotation.txt` to `ZC_RECIPE`.

`ZPP_RECEIPE` has a foreign key to `ZPP_COMP` and this is the only coded field
on that view without a help — every other one already has one. No service
definition change is needed; the F4 service comes from the annotation.

## Not fixed, and why

**`setAdminData` never writes the user.** On Schedule, Job and Recipe it fills
the date and time but not `ernam` / `lastuser`, so a row created in Fiori has a
blank creator. 7,398 recipe rows already show blank — those are legacy, but
anything created through the app joins them. One line per behaviour pool
(`cl_abap_context_info=>get_user_technical_name( )`), three pools; worth doing
in the same pass as the Label fix, but it changes three objects and I would
rather you activate the two above first and confirm them.

**The reopen reason still has nowhere to go** — `ZPP_BATCHN` has columns for who
and when, none for why.

**Close Batch on Batch Status stays off** until someone decides what closing an
`MCHA` batch should mean.

