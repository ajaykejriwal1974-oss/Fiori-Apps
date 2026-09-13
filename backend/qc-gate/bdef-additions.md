# BDEF changes — insert these lines, do NOT paste a whole file

I cannot read behaviour definitions through ADT (the MCP server uses the old
BOPF path and 404s), so every full file I wrote for these two objects was a
reconstruction from the stale repo copy. Three things the live definition has
that the repo copy never did:

1. **`lock master` and `authorization master ( global )` are HEADER clauses**,
   placed between the `define behavior for ...` line and the opening brace,
   with **no semicolons**. The live file carries a comment saying exactly this,
   and naming the same `"action | ancestor | association | changedocument..."`
   parser error we hit — this was learned once already on this project.

2. **Every action carries `( features : instance )`** — including the three
   that already existed. There is a comment explaining why: the Detail view
   binds each footer button to `__OperationControl/<action>`, and that property
   only reaches the OData service when the action declares instance feature
   control. Without it the binding resolves to undefined, UI5 reads it as
   false, and every button is permanently disabled. My replacement dropped it
   from all three existing actions, which would have silently disabled Save,
   Record Results and Usage Decision.

3. **There is no `association _Characteristic;`.** ZI_QC_INSP_CHAR has no
   behaviour definition of its own, and declaring an association to a
   behaviourless entity does not activate. My replacement added it back, which
   is what broke line 14 of the projection.

## ZI_QC_INSP_LOT — insert before the closing brace

```abap
  // Grey QC follow-on: 301 from DRM1 to DPR1 - the movement that actually puts
  // yarn on the dyeing floor. Consumption happens at packing, far too late to
  // be a control point. Carries the receiving batch: the supplier batch in
  // DRM1 becomes the production greige lot in DPR1, which is ZPP_BATCHN-LOTNO.
  action ( features : instance ) releaseToProduction
    parameter ZD_QC_RELEASE_PROD result [1] $self;

  // Post-Dyeing follow-on: operation 0010, work centres DYG00001 / DYG00012.
  // Posts through BAPI_PRODORDCONF_CREATE_TT, the same BAPI ZCO11A calls.
  action ( features : instance ) confirmDyeing
    parameter ZD_QC_CONFIRM_PROD result [1] $self;

  // Post-Winding follow-on: operation 0020, work centre WIN00025, and the
  // point after which packing may proceed.
  action ( features : instance ) confirmWinding
    parameter ZD_QC_CONFIRM_PROD result [1] $self;
```

## ZC_QC_INSP_LOT — insert before the closing brace

```abap
  use action releaseToProduction;
  use action confirmDyeing;
  use action confirmWinding;
```

Do **not** add `use association _Characteristic;` — the base does not declare
it, for the reason in point 3.

## Order

Interface first, activate (let it bring ZBP_I_QC_INSP_LOT along), then the
projection.
