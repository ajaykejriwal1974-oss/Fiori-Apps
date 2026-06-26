# ZDD_SHADE – Shade Master (Dope Dyeing) · RAP Custom Business Object

The shade/colour master from your mapping doc (`ZDD_SHADE`) — a **custom master
object with no standard SAP equivalent**. Per the mapping it's built clean-core
as a **Custom Business Object (RAP)**. This folder is the **developer-extensibility**
implementation (transportable ABAP source). It also unblocks the **shade value
help** stubbed in the F1873 and F3069 adaptation projects.

> This is **not** an adaptation project — it's a standalone RAP business object
> with its own OData service and (optionally) a generated Fiori Elements app.

## Two ways to build it (pick one)

| | Tier-1 Key-user CBO (SAP's first recommendation) | Tier-2 Developer RAP (this folder) |
|---|---|---|
| Where | *Custom Business Objects* Fiori app | ADT (ABAP Dev Tools) / abapGit |
| Effort | No code; define fields + generate UI/service | Author CDS/BDEF/class/service |
| Transport | Auto | Workbench transport |
| When | Plain master data, fast | Need code-level control, complex logic, version in git |

If you just need a maintainable shade list, the **key-user CBO** is faster and
SAP-preferred. Use the source here when you want the object under version control
and full developer control.

## Objects in `src/` (RAP managed scenario)

| File | Object | Role |
|---|---|---|
| `zdd_shade.table-spec.md` | DB table `zdd_shade` | Persistence (create in ADT/SE11 — spec, not abapGit XML) |
| `zi_dd_shade.ddls.asddls` | CDS view entity `ZI_DD_Shade` | Interface / data model (root) |
| `zc_dd_shade.ddls.asddls` | CDS projection `ZC_DD_Shade` | Service projection (transactional_query) |
| `zi_dd_shade.bdef.asbdef` | Behavior definition (managed) | create/update/delete, ETag, determination, validation |
| `zc_dd_shade.bdef.asbdef` | Projection behavior | exposes the operations |
| `zbp_i_dd_shade.clas.abap` | Global behavior pool | `FOR BEHAVIOR OF zi_dd_shade` |
| `zbp_i_dd_shade.clas.locals_imp.abap` | Local handler `lhc_Shade` | `setDefaults` determination + `validateShade` validation |
| `zc_dd_shade.ddlx.asddlxs` | Metadata extension | Fiori Elements List Report / Object Page annotations |
| `zui_dd_shade.srvd.srvdsrv` | Service definition `ZUI_DD_SHADE` | exposes `ZC_DD_Shade` as `Shade` |

### Still to create in ADT (no plain-text source)

- **DB table `zdd_shade`** — per `zdd_shade.table-spec.md`.
- **Service binding `ZUI_DD_SHADE_O4`** — bind `ZUI_DD_SHADE` as **OData V4 – UI**.
  Activate it; this generates the OData service + (optionally) a Fiori Elements
  "Manage Shades" app via the metadata extension above.

## Business logic included

- **Determination `setDefaults`** (on create): defaults `IsActive = true`,
  upper-cases `ColorFamily`.
- **Validation `validateShade`** (on save): `ShadeCode` mandatory; `RgbHex`, when
  set, must be exactly 6 hexadecimal digits.

## Wiring the value help into F1873 / F3069

The adaptation projects currently stub `onShadeValueHelp` (a MessageToast). Once
`ZUI_DD_SHADE_O4` is active, replace the stub with a value-help dialog bound to
the `Shade` entity. Note the **OData version**:

- The classic Manage apps (F1873 etc.) are **OData V2** Fiori Elements; the RAP
  service is **OData V4**. For a custom value help inside a V2 app, either
  consume the V4 service from a standalone `sap.ui.model.odata.v4.ODataModel` in
  the controller extension, **or** additionally expose the shade master as a V2
  service / a CDS value-help (`@Consumption.valueHelpDefinition`) on the field's
  data element so the standard F4 picks it up without UI code.

## Deploy / transport

Standard ABAP transport (workbench request) through your landscape. Activate in
order: table → `ZI_DD_Shade` → `ZC_DD_Shade` → behavior definitions → behavior
class → metadata extension → service definition → service binding.

## Branch

Developed on `claude/fiori-app-extensions-h1nb64`.
