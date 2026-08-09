# Master-Data Build Packs — 12 Fiori Elements Apps (RAP)

**KEJRIWAL / Mango Filaments · S/4HANA 2025 (KSD) · package `ZKGPL_FIORI`**

These are copy-paste "build packs" for the 12 master-data Fiori apps. Each app is a
**managed RAP business object over an existing legacy Z-table** — **none of them needs a
new table** (unlike Shade, which needed `ZDD_SHADE`). Every behaviour definition here has
been **simplified to be class-free** so you do not have to write or generate an ABAP
behaviour class.

---

## How to build one app in ADT (~5 minutes)

In Eclipse ADT, right-click package **`ZKGPL_FIORI`** → *New* → *Other ABAP Repository Object*,
and create the objects **in this exact order** (each waits on the previous one to activate):

| # | Object type (ADT wizard) | Name | Paste |
|---|--------------------------|------|-------|
| 1 | Data Definition (CDS view entity) | `ZI_<App>` | Object 1 — Interface CDS |
| 2 | Data Definition (CDS view entity) | `ZC_<App>` | Object 2 — Projection |
| 3 | Metadata Extension | `ZC_<App>` | Object 3 — Annotations |
| 4 | Behavior Definition (on `ZI_<App>`) | `ZI_<App>` | Object 4 — Interface behaviour (class-free) |
| 5 | Behavior Definition (on `ZC_<App>`) | `ZC_<App>` | Object 5 — Projection behaviour |
| 6 | Service Definition | `ZUI_<APP>` | Object 6 — Service definition |
| 7 | Service Binding | `ZUI_<APP>_O4` | Object 7 — wizard: **OData V4 - UI** → Activate → Publish |

**Rules that make this fast:**
- Activate object 1 before creating 2, etc. (Ctrl+F3 to activate.)
- On the **Behavior Definition** wizard for object 4, pick implementation type **Managed**;
  then *replace the whole generated body* with the pack's Object 4 text (it is already class-free).
- The projection behaviour (object 5) starts with `projection;` — no class needed.
- For the service binding (object 7), choose Binding Type **OData V4 - UI**, assign the
  service definition, then **Activate** and **Publish**.

> ### ⚠ One system-level blocker before any Publish will work
> On this fresh Initial-Shipment KSD system, **OData V4 local publishing is not yet enabled**.
> Basis must run the task list **`SAP_GATEWAY_BASIC_CONFIG`** in transaction **STC01** once
> (this configures the local OData V4 grouping/publishing infrastructure). Until that is done,
> object 7's **Publish** step fails with "Local Publish failed" and no app can be previewed —
> exactly the blocker we hit on Shade Master. Build objects 1–6 now; they activate fine. Publish
> object 7 (all apps) **after** Basis completes the task list. This is a *one-time* system task,
> not per-app.

**What was stripped from the repo originals (all apps):** `strict(2)`, `authorization master`,
`implementation in class ... unique`, and every `determination` / `validation` line — because
those require an ABAP behaviour class. **Kept verbatim:** `managed;`, `persistent table`,
`lock master` (child: `lock dependent`), `create; update; delete;`, `field ( readonly )` on
admin fields where they exist, `field ( mandatory : create )`, and the full `mapping for` blocks.
No `etag master` is emitted where the legacy table has no `TIMESTAMPL` column.

---

## Build order across the 12 apps

Build the **simple single-entity apps first** (fastest, lowest risk), then the composition app last:

1. Truck Master · 2. Checked/Packed By · 3. Transport Code · 4. C-Form Allocation ·
5. Packing Material · 6. Merge Details · 7. Digital Signature · 8. Export Details ·
9. Job Master · 10. Schedule Master · 11. Recipe Master · 12. **Gate Pass (composition — header+item)**

---

# Group A — Simple single-entity masters

## Truck Master

**App:** Truck Master — binds existing legacy DB table **`ztb_truck_mstr`** (legacy alias ZTRUCK).

### Object 1 — Interface CDS view `ZI_Truck`
```cds
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Truck Master - Interface'
@Metadata.allowExtensions: true
// Custom master (Route 7) - managed RAP over legacy table ZTB_TRUCK_MSTR (ZTRUCK).
// Field list mirrors the real Z-table (field dictionary). This legacy table
// has no TIMESTAMPL column, so the optimistic-concurrency ETag is omitted
// (add a TIMESTAMPL column to enable it). Code fields carry in-table text
// (@ObjectModel.text.element) and value helps (on the projection).
define root view entity ZI_Truck
  as select from ztb_truck_mstr
{
  key truckno                as TruckNumber,
      carrier_name           as CarrierName
}
```

### Object 2 — Projection view `ZC_Truck`
```cds
@EndUserText.label: 'Truck Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['TruckNumber']
// Value helps reference standard released VH CDS (VERIFY the exact name per
// release); shade fields use the Shade master ZC_DD_Shade.
define root view entity ZC_Truck
  provider contract transactional_query
  as projection on ZI_Truck
{
  key TruckNumber,
      @Search.defaultSearchElement: true
      CarrierName
}
```

### Object 3 — Metadata extension `ZC_Truck`
```cds
@Metadata.layer: #CORE
@UI: { headerInfo: { typeName: 'Truck', typeNamePlural: 'Trucks',
  title: { type: #STANDARD, value: 'TruckNumber' },
  description: { type: #STANDARD, value: 'CarrierName' } } }
annotate view ZC_Truck with
{
  @UI.facet: [ { id: 'General', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'General', position: 10 } ]
  @UI: { lineItem: [ { position: 10 } ], identification: [ { position: 10 } ], selectionField: [ { position: 10 } ] }
  @EndUserText.label: 'Truck Number'
  TruckNumber;
  @UI: { lineItem: [ { position: 20 } ], identification: [ { position: 20 } ] }
  @EndUserText.label: 'Carrier Name'
  CarrierName;
}
```

### Object 4 — Interface behavior definition `ZI_Truck` (simplified, class-free)
```abap
managed;

define behavior for ZI_Truck alias Truck
persistent table ztb_truck_mstr
lock master
{
  create;
  update;
  delete;

  mapping for ztb_truck_mstr
  {
    TruckNumber          = truckno;
    CarrierName          = carrier_name;
  }
}
```

### Object 5 — Projection behavior definition `ZC_Truck`
```abap
projection;

define behavior for ZC_Truck alias Truck
{
  use create;
  use update;
  use delete;
}
```

### Object 6 — Service definition `ZUI_TRUCK`
```cds
@EndUserText.label: 'Truck Master Service'
define service ZUI_TRUCK {
  expose ZC_Truck as Truck;
}
```

### Object 7 — Service binding
- Name: `ZUI_TRUCK_O4`
- Binding Type: **OData V4 - UI**
- Then **Activate**, then **Publish**.

**Table note:** No `.table-spec.md` — binds existing legacy table `ztb_truck_mstr` — no table to create.

---

## C-Form Allocation Master

**App:** C-Form Allocation Master — binds existing legacy DB table **`zcform1`** (legacy family ZCFORM1/ZFORM/ZFORMS/ZPCFORM).

### Object 1 — Interface CDS view `ZI_Cform`
```cds
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'C-Form Allocation Master - Interface'
@Metadata.allowExtensions: true
// Custom master (Route 7) - managed RAP over legacy table ZCFORM1 (ZCFORM1/ZFORM/ZFORMS/ZPCFORM).
// Field list mirrors the real Z-table (field dictionary). This legacy table
// has no TIMESTAMPL column, so the optimistic-concurrency ETag is omitted
// (add a TIMESTAMPL column to enable it). Code fields carry in-table text
// (@ObjectModel.text.element) and value helps (on the projection).
define root view entity ZI_Cform
  as select from zcform1
{
  key sale_org               as SalesOrganization,
  key cust_code              as Customer,
  key invoice_no             as BillingDocument,
      invoice_dt             as BillingDate,
      invoice_val            as InvoiceValue,
      form_type              as FormType,
      form_no                as FormNumber,
      form_dt                as FormDate,
      allocated_value        as AllocatedValue,
      qty                    as Quantity
}
```

### Object 2 — Projection view `ZC_Cform`
```cds
@EndUserText.label: 'C-Form Allocation Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['SalesOrganization', 'Customer', 'BillingDocument']
// Value helps reference standard released VH CDS (VERIFY the exact name per
// release); shade fields use the Shade master ZC_DD_Shade.
define root view entity ZC_Cform
  provider contract transactional_query
  as projection on ZI_Cform
{
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_SalesOrganizationStdVH', element: 'SalesOrganization' } }]
  key SalesOrganization,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CustomerStdVH', element: 'Customer' } }]
  key Customer,
  key BillingDocument,
      @Search.defaultSearchElement: true
      BillingDate,
      InvoiceValue,
      FormType,
      FormNumber,
      FormDate,
      AllocatedValue,
      Quantity
}
```

### Object 3 — Metadata extension `ZC_Cform`
```cds
@Metadata.layer: #CORE
@UI: { headerInfo: { typeName: 'CForm', typeNamePlural: 'CForms',
  title: { type: #STANDARD, value: 'SalesOrganization' },
  description: { type: #STANDARD, value: 'BillingDate' } } }
annotate view ZC_Cform with
{
  @UI.facet: [ { id: 'General', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'General', position: 10 } ]
  @UI: { lineItem: [ { position: 10 } ], identification: [ { position: 10 } ], selectionField: [ { position: 10 } ] }
  @EndUserText.label: 'Sales Org'
  SalesOrganization;
  @UI: { lineItem: [ { position: 20 } ], identification: [ { position: 20 } ], selectionField: [ { position: 20 } ] }
  @EndUserText.label: 'Customer'
  Customer;
  @UI: { lineItem: [ { position: 30 } ], identification: [ { position: 30 } ], selectionField: [ { position: 30 } ] }
  @EndUserText.label: 'Invoice'
  BillingDocument;
  @UI: { lineItem: [ { position: 40 } ], identification: [ { position: 40 } ] }
  @EndUserText.label: 'Invoice Date'
  BillingDate;
  @UI: { lineItem: [ { position: 50 } ], identification: [ { position: 50 } ] }
  @EndUserText.label: 'Invoice Value'
  InvoiceValue;
  @UI: { lineItem: [ { position: 60 } ], identification: [ { position: 60 } ] }
  @EndUserText.label: 'Form Type'
  FormType;
  @UI: { lineItem: [ { position: 70 } ], identification: [ { position: 70 } ] }
  @EndUserText.label: 'Form Number'
  FormNumber;
  @UI: { lineItem: [ { position: 80 } ], identification: [ { position: 80 } ] }
  @EndUserText.label: 'Form Date'
  FormDate;
  @UI: { lineItem: [ { position: 90 } ], identification: [ { position: 90 } ] }
  @EndUserText.label: 'Allocated Value'
  AllocatedValue;
  @UI: { lineItem: [ { position: 100 } ], identification: [ { position: 100 } ] }
  @EndUserText.label: 'Quantity'
  Quantity;
}
```

### Object 4 — Interface behavior definition `ZI_Cform` (simplified, class-free)
```abap
managed;

define behavior for ZI_Cform alias CForm
persistent table zcform1
lock master
{
  create;
  update;
  delete;

  mapping for zcform1
  {
    SalesOrganization    = sale_org;
    Customer             = cust_code;
    BillingDocument      = invoice_no;
    BillingDate          = invoice_dt;
    InvoiceValue         = invoice_val;
    FormType             = form_type;
    FormNumber           = form_no;
    FormDate             = form_dt;
    AllocatedValue       = allocated_value;
    Quantity             = qty;
  }
}
```

### Object 5 — Projection behavior definition `ZC_Cform`
```abap
projection;

define behavior for ZC_Cform alias CForm
{
  use create;
  use update;
  use delete;
}
```

### Object 6 — Service definition `ZUI_CFORM`
```cds
@EndUserText.label: 'C-Form Allocation Master Service'
define service ZUI_CFORM {
  expose ZC_Cform as CForm;
}
```

### Object 7 — Service binding
- Name: `ZUI_CFORM_O4`
- Binding Type: **OData V4 - UI**
- Then **Activate**, then **Publish**.

**Table note:** No `.table-spec.md` — binds existing legacy table `zcform1` — no table to create.

---

## Checked / Packed By Master

**App:** Checked / Packed By Master — binds existing legacy DB table **`zpp_pcby`** (legacy alias ZPCBY).

### Object 1 — Interface CDS view `ZI_CheckedBy`
```cds
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Checked / Packed By Master - Interface'
@Metadata.allowExtensions: true
// Custom master (Route 7) - managed RAP over legacy table ZPP_PCBY (ZPCBY).
// Field list mirrors the real Z-table (field dictionary). This legacy table
// has no TIMESTAMPL column, so the optimistic-concurrency ETag is omitted
// (add a TIMESTAMPL column to enable it). Code fields carry in-table text
// (@ObjectModel.text.element) and value helps (on the projection).
define root view entity ZI_CheckedBy
  as select from zpp_pcby
{
  key sr_no                  as SerialNumber,
  key pc                     as CheckedPackedFlag,
      usr_name               as UserName
}
```

### Object 2 — Projection view `ZC_CheckedBy`
```cds
@EndUserText.label: 'Checked / Packed By Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['SerialNumber', 'CheckedPackedFlag']
// Value helps reference standard released VH CDS (VERIFY the exact name per
// release); shade fields use the Shade master ZC_DD_Shade.
define root view entity ZC_CheckedBy
  provider contract transactional_query
  as projection on ZI_CheckedBy
{
  key SerialNumber,
  key CheckedPackedFlag,
      @Search.defaultSearchElement: true
      UserName
}
```

### Object 3 — Metadata extension `ZC_CheckedBy`
```cds
@Metadata.layer: #CORE
@UI: { headerInfo: { typeName: 'CheckedBy', typeNamePlural: 'CheckedBys',
  title: { type: #STANDARD, value: 'SerialNumber' },
  description: { type: #STANDARD, value: 'UserName' } } }
annotate view ZC_CheckedBy with
{
  @UI.facet: [ { id: 'General', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'General', position: 10 } ]
  @UI: { lineItem: [ { position: 10 } ], identification: [ { position: 10 } ], selectionField: [ { position: 10 } ] }
  @EndUserText.label: 'Serial Number'
  SerialNumber;
  @UI: { lineItem: [ { position: 20 } ], identification: [ { position: 20 } ], selectionField: [ { position: 20 } ] }
  @EndUserText.label: 'Checked/Packed'
  CheckedPackedFlag;
  @UI: { lineItem: [ { position: 30 } ], identification: [ { position: 30 } ] }
  @EndUserText.label: 'User Name'
  UserName;
}
```

### Object 4 — Interface behavior definition `ZI_CheckedBy` (simplified, class-free)
```abap
managed;

define behavior for ZI_CheckedBy alias CheckedBy
persistent table zpp_pcby
lock master
{
  create;
  update;
  delete;

  mapping for zpp_pcby
  {
    SerialNumber         = sr_no;
    CheckedPackedFlag    = pc;
    UserName             = usr_name;
  }
}
```

### Object 5 — Projection behavior definition `ZC_CheckedBy`
```abap
projection;

define behavior for ZC_CheckedBy alias CheckedBy
{
  use create;
  use update;
  use delete;
}
```

### Object 6 — Service definition `ZUI_CHECKED_BY`
```cds
@EndUserText.label: 'Checked / Packed By Master Service'
define service ZUI_CHECKED_BY {
  expose ZC_CheckedBy as CheckedBy;
}
```

### Object 7 — Service binding
- Name: `ZUI_CHECKED_BY_O4`
- Binding Type: **OData V4 - UI**
- Then **Activate**, then **Publish**.

**Table note:** No `.table-spec.md` — binds existing legacy table `zpp_pcby` — no table to create.

---

## Merge Details Master

**App header** — App name: **Merge Details Master** (`ZUI_MERGE`). Binds existing legacy DB table: **`ZPP_MERGE`** (from `ZI_Merge as select from zpp_merge`).

### Object 1 — Interface CDS view `ZI_Merge`
```cds
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Merge Details Master - Interface'
@Metadata.allowExtensions: true
// Custom master (Route 7) - managed RAP over legacy table ZPP_MERGE (ZMERGE).
// Field list mirrors the real Z-table (field dictionary). This legacy table
// has no TIMESTAMPL column, so the optimistic-concurrency ETag is omitted
// (add a TIMESTAMPL column to enable it). Code fields carry in-table text
// (@ObjectModel.text.element) and value helps (on the projection).
define root view entity ZI_Merge
  as select from zpp_merge
{
  key aurnr                  as OrderNumber,
  key grade                  as Grade,
  key enduse                 as EndUse,
      charg                  as Batch,
      shdcd                  as ShadeCode,
      menge                  as Quantity,
      shdcd2                 as ShadeCode2
}
```

### Object 2 — Projection view `ZC_Merge`
```cds
@EndUserText.label: 'Merge Details Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['OrderNumber', 'Grade', 'EndUse']
// Value helps reference standard released VH CDS (VERIFY the exact name per
// release); shade fields use the Shade master ZC_DD_Shade.
define root view entity ZC_Merge
  provider contract transactional_query
  as projection on ZI_Merge
{
  key OrderNumber,
  key Grade,
  key EndUse,
      @Search.defaultSearchElement: true
      Batch,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZC_DD_Shade', element: 'ShadeCode' } }]
      ShadeCode,
      Quantity,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZC_DD_Shade', element: 'ShadeCode' } }]
      ShadeCode2
}
```

### Object 3 — Metadata extension `ZC_Merge`
```cds
@Metadata.layer: #CORE
@UI: { headerInfo: { typeName: 'Merge', typeNamePlural: 'Merges',
  title: { type: #STANDARD, value: 'OrderNumber' },
  description: { type: #STANDARD, value: 'Batch' } } }
annotate view ZC_Merge with
{
  @UI.facet: [ { id: 'General', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'General', position: 10 } ]
  @UI: { lineItem: [ { position: 10 } ], identification: [ { position: 10 } ], selectionField: [ { position: 10 } ] }
  @EndUserText.label: 'Order Number'
  OrderNumber;
  @UI: { lineItem: [ { position: 20 } ], identification: [ { position: 20 } ], selectionField: [ { position: 20 } ] }
  @EndUserText.label: 'Grade'
  Grade;
  @UI: { lineItem: [ { position: 30 } ], identification: [ { position: 30 } ], selectionField: [ { position: 30 } ] }
  @EndUserText.label: 'End Use'
  EndUse;
  @UI: { lineItem: [ { position: 40 } ], identification: [ { position: 40 } ] }
  @EndUserText.label: 'Batch'
  Batch;
  @UI: { lineItem: [ { position: 50 } ], identification: [ { position: 50 } ] }
  @EndUserText.label: 'Shade'
  ShadeCode;
  @UI: { lineItem: [ { position: 60 } ], identification: [ { position: 60 } ] }
  @EndUserText.label: 'Quantity'
  Quantity;
  @UI: { lineItem: [ { position: 70 } ], identification: [ { position: 70 } ] }
  @EndUserText.label: 'Shade (Alt)'
  ShadeCode2;
}
```

### Object 4 — Interface behavior definition `ZI_Merge` (class-free)
```abap
managed;

define behavior for ZI_Merge alias Merge
persistent table zpp_merge
lock master
{
  create;
  update;
  delete;

  mapping for zpp_merge
  {
    OrderNumber          = aurnr;
    Grade                = grade;
    EndUse               = enduse;
    Batch                = charg;
    ShadeCode            = shdcd;
    Quantity             = menge;
    ShadeCode2           = shdcd2;
  }
}
```

### Object 5 — Projection behavior definition `ZC_Merge`
```abap
projection;

define behavior for ZC_Merge alias Merge
{
  use create;
  use update;
  use delete;
}
```

### Object 6 — Service definition `ZUI_MERGE`
```cds
@EndUserText.label: 'Merge Details Master Service'
define service ZUI_MERGE {
  expose ZC_Merge as Merge;
}
```

### Object 7 — Service binding
Create via wizard: Name `ZUI_MERGE_O4`, Binding Type **OData V4 - UI**, Service Definition `ZUI_MERGE`; then Activate + Publish.

**Table note:** Binds existing legacy table `ZPP_MERGE` — no table to create. (No `.table-spec.md` present.)

---

## Packing Material Master

**App header** — App name: **Packing Material Master** (`ZUI_PACKING_MATERIAL`). Binds existing legacy DB table: **`ZPACK_MAST`** (from `ZI_PackingMaterial as select from zpack_mast`).

### Object 1 — Interface CDS view `ZI_PackingMaterial`
```cds
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Packing Material Master - Interface'
@Metadata.allowExtensions: true
// Custom master (Route 7) - managed RAP over legacy table ZPACK_MAST (ZPACK_MAST).
// Field list mirrors the real Z-table (field dictionary). This legacy table
// has no TIMESTAMPL column, so the optimistic-concurrency ETag is omitted
// (add a TIMESTAMPL column to enable it). Code fields carry in-table text
// (@ObjectModel.text.element) and value helps (on the projection).
define root view entity ZI_PackingMaterial
  as select from zpack_mast
{
  key ptype                  as PackingType,
  key arbpl                  as WorkCenter,
  key matnr                  as Material,
      lgort                  as StorageLocation,
      charg                  as Batch,
      seq                    as Sequence
}
```

### Object 2 — Projection view `ZC_PackingMaterial`
```cds
@EndUserText.label: 'Packing Material Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['PackingType', 'WorkCenter', 'Material']
// Value helps reference standard released VH CDS (VERIFY the exact name per
// release); shade fields use the Shade master ZC_DD_Shade.
define root view entity ZC_PackingMaterial
  provider contract transactional_query
  as projection on ZI_PackingMaterial
{
  key PackingType,
  key WorkCenter,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_MaterialStdVH', element: 'Material' } }]
  key Material,
      @Search.defaultSearchElement: true
      StorageLocation,
      Batch,
      Sequence
}
```

### Object 3 — Metadata extension `ZC_PackingMaterial`
```cds
@Metadata.layer: #CORE
@UI: { headerInfo: { typeName: 'PackMaterial', typeNamePlural: 'PackMaterials',
  title: { type: #STANDARD, value: 'PackingType' },
  description: { type: #STANDARD, value: 'StorageLocation' } } }
annotate view ZC_PackingMaterial with
{
  @UI.facet: [ { id: 'General', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'General', position: 10 } ]
  @UI: { lineItem: [ { position: 10 } ], identification: [ { position: 10 } ], selectionField: [ { position: 10 } ] }
  @EndUserText.label: 'Packing Type'
  PackingType;
  @UI: { lineItem: [ { position: 20 } ], identification: [ { position: 20 } ], selectionField: [ { position: 20 } ] }
  @EndUserText.label: 'Work Center'
  WorkCenter;
  @UI: { lineItem: [ { position: 30 } ], identification: [ { position: 30 } ], selectionField: [ { position: 30 } ] }
  @EndUserText.label: 'Material'
  Material;
  @UI: { lineItem: [ { position: 40 } ], identification: [ { position: 40 } ] }
  @EndUserText.label: 'Storage Location'
  StorageLocation;
  @UI: { lineItem: [ { position: 50 } ], identification: [ { position: 50 } ] }
  @EndUserText.label: 'Batch'
  Batch;
  @UI: { lineItem: [ { position: 60 } ], identification: [ { position: 60 } ] }
  @EndUserText.label: 'Sequence'
  Sequence;
}
```

### Object 4 — Interface behavior definition `ZI_PackingMaterial` (class-free)
```abap
managed;

define behavior for ZI_PackingMaterial alias PackMaterial
persistent table zpack_mast
lock master
{
  create;
  update;
  delete;

  mapping for zpack_mast
  {
    PackingType          = ptype;
    WorkCenter           = arbpl;
    Material             = matnr;
    StorageLocation      = lgort;
    Batch                = charg;
    Sequence             = seq;
  }
}
```

### Object 5 — Projection behavior definition `ZC_PackingMaterial`
```abap
projection;

define behavior for ZC_PackingMaterial alias PackMaterial
{
  use create;
  use update;
  use delete;
}
```

### Object 6 — Service definition `ZUI_PACKING_MATERIAL`
```cds
@EndUserText.label: 'Packing Material Master Service'
define service ZUI_PACKING_MATERIAL {
  expose ZC_PackingMaterial as PackMaterial;
}
```

### Object 7 — Service binding
Create via wizard: Name `ZUI_PACKING_MATERIAL_O4`, Binding Type **OData V4 - UI**, Service Definition `ZUI_PACKING_MATERIAL`; then Activate + Publish.

**Table note:** Binds existing legacy table `ZPACK_MAST` — no table to create. (No `.table-spec.md` present.)

---

## Transport Code Master

**App header** — App name: **Transport Code Master** (`ZUI_TRANSPORT`). Binds existing legacy DB table: **`ZTRANS`** (from `ZI_Transport as select from ztrans`).

### Object 1 — Interface CDS view `ZI_Transport`
```cds
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Transport Code Master - Interface'
@Metadata.allowExtensions: true
// Custom master (Route 7) - managed RAP over legacy table ZTRANS (ZTRANS).
// Field list mirrors the real Z-table (field dictionary). This legacy table
// has no TIMESTAMPL column, so the optimistic-concurrency ETag is omitted
// (add a TIMESTAMPL column to enable it). Code fields carry in-table text
// (@ObjectModel.text.element) and value helps (on the projection).
define root view entity ZI_Transport
  as select from ztrans
{
  key zztrcode               as TransportCode,
  key zztrckno               as TruckNumber,
      zztrdesc               as Description
}
```

### Object 2 — Projection view `ZC_Transport`
```cds
@EndUserText.label: 'Transport Code Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['TransportCode', 'TruckNumber']
// Value helps reference standard released VH CDS (VERIFY the exact name per
// release); shade fields use the Shade master ZC_DD_Shade.
define root view entity ZC_Transport
  provider contract transactional_query
  as projection on ZI_Transport
{
  key TransportCode,
  key TruckNumber,
      @Search.defaultSearchElement: true
      Description
}
```

### Object 3 — Metadata extension `ZC_Transport`
```cds
@Metadata.layer: #CORE
@UI: { headerInfo: { typeName: 'Transport', typeNamePlural: 'Transports',
  title: { type: #STANDARD, value: 'TransportCode' },
  description: { type: #STANDARD, value: 'Description' } } }
annotate view ZC_Transport with
{
  @UI.facet: [ { id: 'General', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'General', position: 10 } ]
  @UI: { lineItem: [ { position: 10 } ], identification: [ { position: 10 } ], selectionField: [ { position: 10 } ] }
  @EndUserText.label: 'Transport Code'
  TransportCode;
  @UI: { lineItem: [ { position: 20 } ], identification: [ { position: 20 } ], selectionField: [ { position: 20 } ] }
  @EndUserText.label: 'Truck Number'
  TruckNumber;
  @UI: { lineItem: [ { position: 30 } ], identification: [ { position: 30 } ] }
  @EndUserText.label: 'Description'
  Description;
}
```

### Object 4 — Interface behavior definition `ZI_Transport` (class-free)
```abap
managed;

define behavior for ZI_Transport alias Transport
persistent table ztrans
lock master
{
  create;
  update;
  delete;

  mapping for ztrans
  {
    TransportCode        = zztrcode;
    TruckNumber          = zztrckno;
    Description          = zztrdesc;
  }
}
```

### Object 5 — Projection behavior definition `ZC_Transport`
```abap
projection;

define behavior for ZC_Transport alias Transport
{
  use create;
  use update;
  use delete;
}
```

### Object 6 — Service definition `ZUI_TRANSPORT`
```cds
@EndUserText.label: 'Transport Code Master Service'
define service ZUI_TRANSPORT {
  expose ZC_Transport as Transport;
}
```

### Object 7 — Service binding
Create via wizard: Name `ZUI_TRANSPORT_O4`, Binding Type **OData V4 - UI**, Service Definition `ZUI_TRANSPORT`; then Activate + Publish.

**Table note:** Binds existing legacy table `ZTRANS` — no table to create. (No `.table-spec.md` present.)

---

## Digital Signature Master

**App:** Digital Signature Master (managed RAP) — binds DB table **`ZTDIGI_SIGN`**.
**Table note:** No `.table-spec.md`. `ZTDIGI_SIGN` already exists — binds existing legacy table; no table to create. (No `TIMESTAMPL` column, so no ETag.)

### Object 1 — Interface CDS view `ZI_DigitalSignature`
```cds
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Digital Signature Master - Interface'
@Metadata.allowExtensions: true
define root view entity ZI_DigitalSignature
  as select from ztdigi_sign
{
  key bukrs                  as CompanyCode,
      email                  as Email,
      pwd                    as Password,
      ip                     as IpAddress,
      pfx                    as PfxPrefix,
      source_folder          as SourceFolder,
      dest_folder            as DestinationFolder
}
```

### Object 2 — Projection view `ZC_DigitalSignature`
```cds
@EndUserText.label: 'Digital Signature Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['CompanyCode']
define root view entity ZC_DigitalSignature
  provider contract transactional_query
  as projection on ZI_DigitalSignature
{
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CompanyCodeStdVH', element: 'CompanyCode' } }]
  key CompanyCode,
      @Search.defaultSearchElement: true
      Email,
      Password,
      IpAddress,
      PfxPrefix,
      SourceFolder,
      DestinationFolder
}
```

### Object 3 — Metadata extension `ZC_DigitalSignature`
```cds
@Metadata.layer: #CORE
@UI: { headerInfo: { typeName: 'DigiSign', typeNamePlural: 'DigiSigns',
  title: { type: #STANDARD, value: 'CompanyCode' },
  description: { type: #STANDARD, value: 'Email' } } }
annotate view ZC_DigitalSignature with
{
  @UI.facet: [ { id: 'General', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'General', position: 10 } ]
  @UI: { lineItem: [ { position: 10 } ], identification: [ { position: 10 } ], selectionField: [ { position: 10 } ] }
  @EndUserText.label: 'Company Code'
  CompanyCode;
  @UI: { lineItem: [ { position: 20 } ], identification: [ { position: 20 } ] }
  @EndUserText.label: 'Email'
  Email;
  @UI: { lineItem: [ { position: 30 } ], identification: [ { position: 30 } ] }
  @EndUserText.label: 'Password'
  Password;
  @UI: { lineItem: [ { position: 40 } ], identification: [ { position: 40 } ] }
  @EndUserText.label: 'IP Address'
  IpAddress;
  @UI: { lineItem: [ { position: 50 } ], identification: [ { position: 50 } ] }
  @EndUserText.label: 'PFX'
  PfxPrefix;
  @UI: { lineItem: [ { position: 60 } ], identification: [ { position: 60 } ] }
  @EndUserText.label: 'Source Folder'
  SourceFolder;
  @UI: { lineItem: [ { position: 70 } ], identification: [ { position: 70 } ] }
  @EndUserText.label: 'Destination Folder'
  DestinationFolder;
}
```

### Object 4 — Interface behavior definition `ZI_DigitalSignature` (simplified, class-free)
```abap
managed;

define behavior for ZI_DigitalSignature alias DigiSign
persistent table ztdigi_sign
lock master
{
  create;
  update;
  delete;

  field ( mandatory : create ) CompanyCode;

  mapping for ztdigi_sign
  {
    CompanyCode          = bukrs;
    Email                = email;
    Password             = pwd;
    IpAddress            = ip;
    PfxPrefix            = pfx;
    SourceFolder         = source_folder;
    DestinationFolder    = dest_folder;
  }
}
```

### Object 5 — Projection behavior definition `ZC_DigitalSignature`
```abap
projection;

define behavior for ZC_DigitalSignature alias DigiSign
{
  use create;
  use update;
  use delete;
}
```

### Object 6 — Service definition `ZUI_DIGITAL_SIGNATURE`
```cds
@EndUserText.label: 'Digital Signature Master Service'
define service ZUI_DIGITAL_SIGNATURE {
  expose ZC_DigitalSignature as DigiSign;
}
```

### Object 7 — Service binding
Create via wizard: Name `ZUI_DIGITAL_SIGNATURE_O4`, Binding Type **OData V4 - UI**, Service Definition `ZUI_DIGITAL_SIGNATURE`; then Activate + Publish.

---

## Export Details Master

**App:** Export Details Master (managed RAP) — binds DB table **`ZEXP`**.
**Table note:** No `.table-spec.md`. `ZEXP` already exists — binds existing legacy table; no table to create. (No `TIMESTAMPL` column, so no ETag.)

### Object 1 — Interface CDS view `ZI_ExportDetail`
```cds
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Export Details Master - Interface'
@Metadata.allowExtensions: true
define root view entity ZI_ExportDetail
  as select from zexp
{
  key vbeln                  as BillingDocument,
  key kschl                  as ConditionType,
      @Semantics.amount.currencyCode: 'Currency'
      netwr                  as NetValue,
      @Semantics.currencyCode: true
      waerk                  as Currency,
      kursk                  as ExchangeRate,
      fkdat                  as BillingDate
}
```

### Object 2 — Projection view `ZC_ExportDetail`
```cds
@EndUserText.label: 'Export Details Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['BillingDocument', 'ConditionType']
define root view entity ZC_ExportDetail
  provider contract transactional_query
  as projection on ZI_ExportDetail
{
  key BillingDocument,
  key ConditionType,
      NetValue,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CurrencyStdVH', element: 'Currency' } }]
      Currency,
      @Search.defaultSearchElement: true
      ExchangeRate,
      BillingDate
}
```

### Object 3 — Metadata extension `ZC_ExportDetail`
```cds
@Metadata.layer: #CORE
@UI: { headerInfo: { typeName: 'ExportDetail', typeNamePlural: 'ExportDetails',
  title: { type: #STANDARD, value: 'BillingDocument' },
  description: { type: #STANDARD, value: 'ExchangeRate' } } }
annotate view ZC_ExportDetail with
{
  @UI.facet: [ { id: 'General', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'General', position: 10 } ]
  @UI: { lineItem: [ { position: 10 } ], identification: [ { position: 10 } ], selectionField: [ { position: 10 } ] }
  @EndUserText.label: 'Billing Document'
  BillingDocument;
  @UI: { lineItem: [ { position: 20 } ], identification: [ { position: 20 } ], selectionField: [ { position: 20 } ] }
  @EndUserText.label: 'Condition Type'
  ConditionType;
  @UI: { lineItem: [ { position: 30 } ], identification: [ { position: 30 } ] }
  @EndUserText.label: 'Net Value'
  NetValue;
  @UI: { lineItem: [ { position: 40 } ], identification: [ { position: 40 } ] }
  @EndUserText.label: 'Currency'
  Currency;
  @UI: { lineItem: [ { position: 50 } ], identification: [ { position: 50 } ] }
  @EndUserText.label: 'Exchange Rate'
  ExchangeRate;
  @UI: { lineItem: [ { position: 60 } ], identification: [ { position: 60 } ] }
  @EndUserText.label: 'Billing Date'
  BillingDate;
}
```

### Object 4 — Interface behavior definition `ZI_ExportDetail` (simplified, class-free)
```abap
managed;

define behavior for ZI_ExportDetail alias ExportDetail
persistent table zexp
lock master
{
  create;
  update;
  delete;

  field ( mandatory : create ) BillingDocument;

  mapping for zexp
  {
    BillingDocument      = vbeln;
    ConditionType        = kschl;
    NetValue             = netwr;
    Currency             = waerk;
    ExchangeRate         = kursk;
    BillingDate          = fkdat;
  }
}
```

### Object 5 — Projection behavior definition `ZC_ExportDetail`
```abap
projection;

define behavior for ZC_ExportDetail alias ExportDetail
{
  use create;
  use update;
  use delete;
}
```

### Object 6 — Service definition `ZUI_EXPORT_DETAIL`
```cds
@EndUserText.label: 'Export Details Master Service'
define service ZUI_EXPORT_DETAIL {
  expose ZC_ExportDetail as ExportDetail;
}
```

### Object 7 — Service binding
Create via wizard: Name `ZUI_EXPORT_DETAIL_O4`, Binding Type **OData V4 - UI**, Service Definition `ZUI_EXPORT_DETAIL`; then Activate + Publish.

---

---

# Group B — Masters with admin/audit fields

## Recipe Master (Dyeing Recipe Master)

**App header** — App: **Dyeing Recipe Master** · Bound legacy DB table: **`zpp_receipe`** (from `ZI_Recipe as select from zpp_receipe`).

### Object 1 — Interface CDS view `ZI_Recipe` (`zi_recipe.ddls.asddls`)
```cds
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Dyeing Recipe Master - Interface'
@Metadata.allowExtensions: true
// Custom master (Route 7) - managed RAP over legacy table ZPP_RECEIPE (ZRECP01/02/03).
// Field list mirrors the real Z-table (field dictionary). This legacy table
// has no TIMESTAMPL column, so the optimistic-concurrency ETag is omitted
// (add a TIMESTAMPL column to enable it). Code fields carry in-table text
// (@ObjectModel.text.element) and value helps (on the projection).
define root view entity ZI_Recipe
  as select from zpp_receipe
{
  key werks                  as Plant,
      @ObjectModel.text.element: ['GreyItemDesc']
  key grey_code              as GreyCode,
      @ObjectModel.text.element: ['DyeItemDesc']
  key dye_code               as DyeCode,
  key shdcd                  as ShadeCode,
  key posnr                  as ItemNumber,
      @Semantics.text: true
      grey_item              as GreyItemDesc,
      @Semantics.text: true
      dye_item               as DyeItemDesc,
      @ObjectModel.text.element: ['ComponentDesc']
      component              as Component,
      @Semantics.text: true
      comp_desc              as ComponentDesc,
      comp_type              as ComponentType,
      @Semantics.quantity.unitOfMeasure: 'SalesUnit'
      ratio                  as Ratio,
      @Semantics.unitOfMeasure: true
      vrkme                  as SalesUnit,
      remarks                as Remarks,
      @Semantics.user.createdBy: true
      ernam                  as CreatedBy,
      erdat                  as CreatedOnDate,
      erzet                  as CreatedAtTime,
      @Semantics.user.lastChangedBy: true
      lastuser               as LastChangedBy,
      lastdate               as LastChangedDate,
      lasttime               as LastChangedTime
}
```

### Object 2 — Projection view `ZC_Recipe` (`zc_recipe.ddls.asddls`)
```cds
@EndUserText.label: 'Dyeing Recipe Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['Plant', 'GreyCode', 'DyeCode', 'ShadeCode', 'ItemNumber']
// Value helps reference standard released VH CDS (VERIFY the exact name per
// release); shade fields use the Shade master ZC_DD_Shade.
define root view entity ZC_Recipe
  provider contract transactional_query
  as projection on ZI_Recipe
{
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_PlantStdVH', element: 'Plant' } }]
  key Plant,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_MaterialStdVH', element: 'Material' } }]
  key GreyCode,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_MaterialStdVH', element: 'Material' } }]
  key DyeCode,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZC_DD_Shade', element: 'ShadeCode' } }]
  key ShadeCode,
  key ItemNumber,
      @Search.defaultSearchElement: true
      GreyItemDesc,
      DyeItemDesc,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_MaterialStdVH', element: 'Material' } }]
      Component,
      ComponentDesc,
      ComponentType,
      Ratio,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_UnitOfMeasureStdVH', element: 'UnitOfMeasure' } }]
      SalesUnit,
      Remarks,
      CreatedBy,
      CreatedOnDate,
      CreatedAtTime,
      LastChangedBy,
      LastChangedDate,
      LastChangedTime
}
```

### Object 3 — Metadata extension `ZC_Recipe` (`zc_recipe.ddlx.asddlxs`)
```cds
@Metadata.layer: #CORE
@UI: { headerInfo: { typeName: 'Recipe', typeNamePlural: 'Recipes',
  title: { type: #STANDARD, value: 'Plant' },
  description: { type: #STANDARD, value: 'GreyItemDesc' } } }
annotate view ZC_Recipe with
{
  @UI.facet: [ { id: 'General', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'General', position: 10 } ]
  @UI: { lineItem: [ { position: 10 } ], identification: [ { position: 10 } ], selectionField: [ { position: 10 } ] }
  @EndUserText.label: 'Plant'
  Plant;
  @UI: { lineItem: [ { position: 20 } ], identification: [ { position: 20 } ], selectionField: [ { position: 20 } ] }
  @EndUserText.label: 'Grey Material'
  GreyCode;
  @UI: { lineItem: [ { position: 30 } ], identification: [ { position: 30 } ], selectionField: [ { position: 30 } ] }
  @EndUserText.label: 'Dyed Material'
  DyeCode;
  @UI: { lineItem: [ { position: 40 } ], identification: [ { position: 40 } ], selectionField: [ { position: 40 } ] }
  @EndUserText.label: 'Shade'
  ShadeCode;
  @UI: { lineItem: [ { position: 50 } ], identification: [ { position: 50 } ], selectionField: [ { position: 50 } ] }
  @EndUserText.label: 'Item'
  ItemNumber;
  @UI: { lineItem: [ { position: 60 } ], identification: [ { position: 60 } ] }
  @EndUserText.label: 'Grey Description'
  GreyItemDesc;
  @UI: { lineItem: [ { position: 70 } ], identification: [ { position: 70 } ] }
  @EndUserText.label: 'Dyed Description'
  DyeItemDesc;
  @UI: { lineItem: [ { position: 80 } ], identification: [ { position: 80 } ] }
  @EndUserText.label: 'Component'
  Component;
  @UI: { lineItem: [ { position: 90 } ], identification: [ { position: 90 } ] }
  @EndUserText.label: 'Component Description'
  ComponentDesc;
  @UI: { lineItem: [ { position: 100 } ], identification: [ { position: 100 } ] }
  @EndUserText.label: 'Component Type'
  ComponentType;
  @UI: { lineItem: [ { position: 110 } ], identification: [ { position: 110 } ] }
  @EndUserText.label: 'Ratio'
  Ratio;
  @UI: { lineItem: [ { position: 120 } ], identification: [ { position: 120 } ] }
  @EndUserText.label: 'Unit'
  SalesUnit;
  @UI: { lineItem: [ { position: 130 } ], identification: [ { position: 130 } ] }
  @EndUserText.label: 'Remarks'
  Remarks;
  @UI: { lineItem: [ { position: 140 } ], identification: [ { position: 140 } ] }
  @EndUserText.label: 'Created By'
  CreatedBy;
  @UI: { lineItem: [ { position: 150 } ], identification: [ { position: 150 } ] }
  @EndUserText.label: 'Changed By'
  LastChangedBy;
}
```

### Object 4 — Interface behavior definition `ZI_Recipe` (SIMPLIFIED, class-free)
```abap
managed;

define behavior for ZI_Recipe alias Recipe
persistent table zpp_receipe
lock master
{
  create;
  update;
  delete;

  field ( mandatory : create ) Plant;
  field ( readonly ) CreatedBy, CreatedOnDate, CreatedAtTime, LastChangedBy, LastChangedDate, LastChangedTime;

  mapping for zpp_receipe
  {
    Plant                = werks;
    GreyCode             = grey_code;
    DyeCode              = dye_code;
    ShadeCode            = shdcd;
    ItemNumber           = posnr;
    GreyItemDesc         = grey_item;
    DyeItemDesc          = dye_item;
    Component            = component;
    ComponentDesc        = comp_desc;
    ComponentType        = comp_type;
    Ratio                = ratio;
    SalesUnit            = vrkme;
    Remarks              = remarks;
    CreatedBy            = ernam;
    CreatedOnDate        = erdat;
    CreatedAtTime        = erzet;
    LastChangedBy        = lastuser;
    LastChangedDate      = lastdate;
    LastChangedTime      = lasttime;
  }
}
```

### Object 5 — Projection behavior definition `ZC_Recipe`
```abap
projection;

define behavior for ZC_Recipe alias Recipe
{
  use create;
  use update;
  use delete;
}
```

### Object 6 — Service definition `ZUI_RECIPE` (`zui_recipe.srvd.srvdsrv`)
```cds
@EndUserText.label: 'Dyeing Recipe Master Service'
define service ZUI_RECIPE {
  expose ZC_Recipe as Recipe;
}
```

### Object 7 — Service binding
Create via wizard: Name `ZUI_RECIPE_O4`, Binding Type **OData V4 - UI**, Service Definition `ZUI_RECIPE`; then Activate + Publish.

**Table note:** Binds existing legacy table `zpp_receipe` — no table to create.

---

## Schedule Master

**App header** — App: **Schedule Master** · Bound legacy DB table: **`zpp_schedulen`** (from `ZI_Schedule as select from zpp_schedulen`).

### Object 1 — Interface CDS view `ZI_Schedule` (`zi_schedule.ddls.asddls`)
```cds
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Schedule Master - Interface'
@Metadata.allowExtensions: true
// Custom master (Route 7) - managed RAP over legacy table ZPP_SCHEDULEN (ZSCH01/02/03(N)).
// Field list mirrors the real Z-table (field dictionary). This legacy table
// has no TIMESTAMPL column, so the optimistic-concurrency ETag is omitted
// (add a TIMESTAMPL column to enable it). Code fields carry in-table text
// (@ObjectModel.text.element) and value helps (on the projection).
define root view entity ZI_Schedule
  as select from zpp_schedulen
{
  key schno                  as ScheduleNumber,
  key gjahr                  as FiscalYear,
      werks                  as Plant,
      kdno                   as CardNumber,
      schdt                  as ScheduleDate,
      schtime                as ScheduleTime,
      vbeln                  as SalesDocument,
      posnr                  as SalesItem,
      dyedt                  as DyeingDate,
      @ObjectModel.text.element: ['MaterialDesc']
      matnr                  as Material,
      @Semantics.text: true
      maktx                  as MaterialDesc,
      @Semantics.quantity.unitOfMeasure: 'SalesUnit'
      sch_qty                as ScheduleQty,
      @Semantics.unitOfMeasure: true
      vrkme                  as SalesUnit,
      shdcd                  as ShadeCode,
      remarks                as Remarks,
      complete               as CompleteFlag,
      delind                 as DeletionFlag,
      @Semantics.user.createdBy: true
      ernam                  as CreatedBy,
      erdat                  as CreatedOnDate,
      erzet                  as CreatedAtTime,
      @Semantics.user.lastChangedBy: true
      lastuser               as LastChangedBy,
      lastdate               as LastChangedDate,
      lasttime               as LastChangedTime
}
```

### Object 2 — Projection view `ZC_Schedule` (`zc_schedule.ddls.asddls`)
```cds
@EndUserText.label: 'Schedule Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['ScheduleNumber', 'FiscalYear']
// Value helps reference standard released VH CDS (VERIFY the exact name per
// release); shade fields use the Shade master ZC_DD_Shade.
define root view entity ZC_Schedule
  provider contract transactional_query
  as projection on ZI_Schedule
{
  key ScheduleNumber,
  key FiscalYear,
      @Search.defaultSearchElement: true
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_PlantStdVH', element: 'Plant' } }]
      Plant,
      CardNumber,
      ScheduleDate,
      ScheduleTime,
      SalesDocument,
      SalesItem,
      DyeingDate,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_MaterialStdVH', element: 'Material' } }]
      Material,
      MaterialDesc,
      ScheduleQty,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_UnitOfMeasureStdVH', element: 'UnitOfMeasure' } }]
      SalesUnit,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZC_DD_Shade', element: 'ShadeCode' } }]
      ShadeCode,
      Remarks,
      CompleteFlag,
      DeletionFlag,
      CreatedBy,
      CreatedOnDate,
      CreatedAtTime,
      LastChangedBy,
      LastChangedDate,
      LastChangedTime
}
```

### Object 3 — Metadata extension `ZC_Schedule` (`zc_schedule.ddlx.asddlxs`)
```cds
@Metadata.layer: #CORE
@UI: { headerInfo: { typeName: 'Schedule', typeNamePlural: 'Schedules',
  title: { type: #STANDARD, value: 'ScheduleNumber' },
  description: { type: #STANDARD, value: 'Plant' } } }
annotate view ZC_Schedule with
{
  @UI.facet: [ { id: 'General', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'General', position: 10 } ]
  @UI: { lineItem: [ { position: 10 } ], identification: [ { position: 10 } ], selectionField: [ { position: 10 } ] }
  @EndUserText.label: 'Schedule Number'
  ScheduleNumber;
  @UI: { lineItem: [ { position: 20 } ], identification: [ { position: 20 } ], selectionField: [ { position: 20 } ] }
  @EndUserText.label: 'Fiscal Year'
  FiscalYear;
  @UI: { lineItem: [ { position: 30 } ], identification: [ { position: 30 } ] }
  @EndUserText.label: 'Plant'
  Plant;
  @UI: { lineItem: [ { position: 40 } ], identification: [ { position: 40 } ] }
  @EndUserText.label: 'Card Number'
  CardNumber;
  @UI: { lineItem: [ { position: 50 } ], identification: [ { position: 50 } ] }
  @EndUserText.label: 'Schedule Date'
  ScheduleDate;
  @UI: { lineItem: [ { position: 60 } ], identification: [ { position: 60 } ] }
  @EndUserText.label: 'Schedule Time'
  ScheduleTime;
  @UI: { lineItem: [ { position: 70 } ], identification: [ { position: 70 } ] }
  @EndUserText.label: 'Sales Document'
  SalesDocument;
  @UI: { lineItem: [ { position: 80 } ], identification: [ { position: 80 } ] }
  @EndUserText.label: 'Sales Item'
  SalesItem;
  @UI: { lineItem: [ { position: 90 } ], identification: [ { position: 90 } ] }
  @EndUserText.label: 'Dyeing Date'
  DyeingDate;
  @UI: { lineItem: [ { position: 100 } ], identification: [ { position: 100 } ] }
  @EndUserText.label: 'Material'
  Material;
  @UI: { lineItem: [ { position: 110 } ], identification: [ { position: 110 } ] }
  @EndUserText.label: 'Material Description'
  MaterialDesc;
  @UI: { lineItem: [ { position: 120 } ], identification: [ { position: 120 } ] }
  @EndUserText.label: 'Schedule Qty'
  ScheduleQty;
  @UI: { lineItem: [ { position: 130 } ], identification: [ { position: 130 } ] }
  @EndUserText.label: 'Unit'
  SalesUnit;
  @UI: { lineItem: [ { position: 140 } ], identification: [ { position: 140 } ] }
  @EndUserText.label: 'Shade'
  ShadeCode;
  @UI: { lineItem: [ { position: 150 } ], identification: [ { position: 150 } ] }
  @EndUserText.label: 'Remarks'
  Remarks;
  @UI: { lineItem: [ { position: 160 } ], identification: [ { position: 160 } ] }
  @EndUserText.label: 'Complete'
  CompleteFlag;
  @UI: { lineItem: [ { position: 170 } ], identification: [ { position: 170 } ] }
  @EndUserText.label: 'Deleted'
  DeletionFlag;
  @UI: { lineItem: [ { position: 180 } ], identification: [ { position: 180 } ] }
  @EndUserText.label: 'Created By'
  CreatedBy;
  @UI: { lineItem: [ { position: 190 } ], identification: [ { position: 190 } ] }
  @EndUserText.label: 'Changed By'
  LastChangedBy;
}
```

### Object 4 — Interface behavior definition `ZI_Schedule` (SIMPLIFIED, class-free)
```abap
managed;

define behavior for ZI_Schedule alias Schedule
persistent table zpp_schedulen
lock master
{
  create;
  update;
  delete;

  field ( mandatory : create ) ScheduleNumber;
  field ( readonly ) CreatedBy, CreatedOnDate, CreatedAtTime, LastChangedBy, LastChangedDate, LastChangedTime;

  mapping for zpp_schedulen
  {
    ScheduleNumber       = schno;
    FiscalYear           = gjahr;
    Plant                = werks;
    CardNumber           = kdno;
    ScheduleDate         = schdt;
    ScheduleTime         = schtime;
    SalesDocument        = vbeln;
    SalesItem            = posnr;
    DyeingDate           = dyedt;
    Material             = matnr;
    MaterialDesc         = maktx;
    ScheduleQty          = sch_qty;
    SalesUnit            = vrkme;
    ShadeCode            = shdcd;
    Remarks              = remarks;
    CompleteFlag         = complete;
    DeletionFlag         = delind;
    CreatedBy            = ernam;
    CreatedOnDate        = erdat;
    CreatedAtTime        = erzet;
    LastChangedBy        = lastuser;
    LastChangedDate      = lastdate;
    LastChangedTime      = lasttime;
  }
}
```

### Object 5 — Projection behavior definition `ZC_Schedule`
```abap
projection;

define behavior for ZC_Schedule alias Schedule
{
  use create;
  use update;
  use delete;
}
```

### Object 6 — Service definition `ZUI_SCHEDULE` (`zui_schedule.srvd.srvdsrv`)
```cds
@EndUserText.label: 'Schedule Master Service'
define service ZUI_SCHEDULE {
  expose ZC_Schedule as Schedule;
}
```

### Object 7 — Service binding
Create via wizard: Name `ZUI_SCHEDULE_O4`, Binding Type **OData V4 - UI**, Service Definition `ZUI_SCHEDULE`; then Activate + Publish.

**Table note:** Binds existing legacy table `zpp_schedulen` — no table to create.

---

## Job Master

**App header** — App: **Job Master** · Bound legacy DB table: **`zpp_jobn`** (from `ZI_Job as select from zpp_jobn`).

### Object 1 — Interface CDS view `ZI_Job` (`zi_job.ddls.asddls`)
```cds
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Job Master - Interface'
@Metadata.allowExtensions: true
// Custom master (Route 7) - managed RAP over legacy table ZPP_JOBN (ZJOB01/02/03(N)).
// Field list mirrors the real Z-table (field dictionary). This legacy table
// has no TIMESTAMPL column, so the optimistic-concurrency ETag is omitted
// (add a TIMESTAMPL column to enable it). Code fields carry in-table text
// (@ObjectModel.text.element) and value helps (on the projection).
define root view entity ZI_Job
  as select from zpp_jobn
{
  key jobno                  as JobNumber,
      batchno                as BatchNumber,
      schno                  as ScheduleNumber,
      werks                  as Plant,
      dye_arbpl              as DyeingWorkCenter,
      win_arbpl              as WindingWorkCenter,
      delind                 as DeletionFlag,
      @Semantics.user.createdBy: true
      ernam                  as CreatedBy,
      erdat                  as CreatedOnDate,
      erzet                  as CreatedAtTime,
      @Semantics.user.lastChangedBy: true
      lastuser               as LastChangedBy,
      lastdate               as LastChangedDate,
      lasttime               as LastChangedTime
}
```

### Object 2 — Projection view `ZC_Job` (`zc_job.ddls.asddls`)
```cds
@EndUserText.label: 'Job Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['JobNumber']
// Value helps reference standard released VH CDS (VERIFY the exact name per
// release); shade fields use the Shade master ZC_DD_Shade.
define root view entity ZC_Job
  provider contract transactional_query
  as projection on ZI_Job
{
  key JobNumber,
      @Search.defaultSearchElement: true
      BatchNumber,
      ScheduleNumber,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_PlantStdVH', element: 'Plant' } }]
      Plant,
      DyeingWorkCenter,
      WindingWorkCenter,
      DeletionFlag,
      CreatedBy,
      CreatedOnDate,
      CreatedAtTime,
      LastChangedBy,
      LastChangedDate,
      LastChangedTime
}
```

### Object 3 — Metadata extension `ZC_Job` (`zc_job.ddlx.asddlxs`)
```cds
@Metadata.layer: #CORE
@UI: { headerInfo: { typeName: 'Job', typeNamePlural: 'Jobs',
  title: { type: #STANDARD, value: 'JobNumber' },
  description: { type: #STANDARD, value: 'BatchNumber' } } }
annotate view ZC_Job with
{
  @UI.facet: [ { id: 'General', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'General', position: 10 } ]
  @UI: { lineItem: [ { position: 10 } ], identification: [ { position: 10 } ], selectionField: [ { position: 10 } ] }
  @EndUserText.label: 'Job Number'
  JobNumber;
  @UI: { lineItem: [ { position: 20 } ], identification: [ { position: 20 } ] }
  @EndUserText.label: 'Batch Number'
  BatchNumber;
  @UI: { lineItem: [ { position: 30 } ], identification: [ { position: 30 } ] }
  @EndUserText.label: 'Schedule Number'
  ScheduleNumber;
  @UI: { lineItem: [ { position: 40 } ], identification: [ { position: 40 } ] }
  @EndUserText.label: 'Plant'
  Plant;
  @UI: { lineItem: [ { position: 50 } ], identification: [ { position: 50 } ] }
  @EndUserText.label: 'Dyeing Work Center'
  DyeingWorkCenter;
  @UI: { lineItem: [ { position: 60 } ], identification: [ { position: 60 } ] }
  @EndUserText.label: 'Winding Work Center'
  WindingWorkCenter;
  @UI: { lineItem: [ { position: 70 } ], identification: [ { position: 70 } ] }
  @EndUserText.label: 'Deleted'
  DeletionFlag;
  @UI: { lineItem: [ { position: 80 } ], identification: [ { position: 80 } ] }
  @EndUserText.label: 'Created By'
  CreatedBy;
  @UI: { lineItem: [ { position: 90 } ], identification: [ { position: 90 } ] }
  @EndUserText.label: 'Changed By'
  LastChangedBy;
}
```

### Object 4 — Interface behavior definition `ZI_Job` (SIMPLIFIED, class-free)
```abap
managed;

define behavior for ZI_Job alias Job
persistent table zpp_jobn
lock master
{
  create;
  update;
  delete;

  field ( mandatory : create ) JobNumber;
  field ( readonly ) CreatedBy, CreatedOnDate, CreatedAtTime, LastChangedBy, LastChangedDate, LastChangedTime;

  mapping for zpp_jobn
  {
    JobNumber            = jobno;
    BatchNumber          = batchno;
    ScheduleNumber       = schno;
    Plant                = werks;
    DyeingWorkCenter     = dye_arbpl;
    WindingWorkCenter    = win_arbpl;
    DeletionFlag         = delind;
    CreatedBy            = ernam;
    CreatedOnDate        = erdat;
    CreatedAtTime        = erzet;
    LastChangedBy        = lastuser;
    LastChangedDate      = lastdate;
    LastChangedTime      = lasttime;
  }
}
```

### Object 5 — Projection behavior definition `ZC_Job`
```abap
projection;

define behavior for ZC_Job alias Job
{
  use create;
  use update;
  use delete;
}
```

### Object 6 — Service definition `ZUI_JOB` (`zui_job.srvd.srvdsrv`)
```cds
@EndUserText.label: 'Job Master Service'
define service ZUI_JOB {
  expose ZC_Job as Job;
}
```

### Object 7 — Service binding
Create via wizard: Name `ZUI_JOB_O4`, Binding Type **OData V4 - UI**, Service Definition `ZUI_JOB`; then Activate + Publish.

**Table note:** Binds existing legacy table `zpp_jobn` — no table to create.

# Group C — Composition (build last)

## Gate Pass (composition: header + item)

**App:** Gate Pass (managed RAP composition) — binds DB tables **`ZGP_HDR`** (header) and **`ZGP_ITEM`** (item); **`ZGP_PART`** exposed as a read-only association.
**Table note:** No `.table-spec.md`. `ZGP_HDR` / `ZGP_ITEM` / `ZGP_PART` already exist — binds existing legacy tables; no table to create.
**Composition note:** `ZGP_PART` has keys `GPNUM + ZITEM + CNT` but **no `MJAHR`**, so it is exposed as a plain **association** (`_Part`), not a composition child — no behavior/mapping for it. (Add `MJAHR` to `ZGP_PART` later to fold it into the composition tree.)

Creation order: all interface views (header → item → part) → projections → metadata extensions → behavior definition → projection behavior → service + binding.

### Object 1a — Interface CDS view (header) `ZI_GatePass`
```cds
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Gate Pass - Interface (header)'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['GpNumber', 'FiscalYear']
define root view entity ZI_GatePass
  as select from zgp_hdr
  composition [0..*] of ZI_GatePassItem as _Item
{
  key gpnum                  as GpNumber,
  key mjahr                  as FiscalYear,
      dtype                  as DocumentType,
      werks                  as Plant,
      dept                   as Department,
      vhnum                  as VehicleNumber,
      gindat                 as InDate,
      gintme                 as InTime,
      gotdat                 as OutDate,
      gottme                 as OutTime,
      remks                  as Remarks,
      cre_user               as CreatedByUser,
      @Semantics.user.createdBy: true
      ernam                  as CreatedBy,
      erdat                  as CreatedOnDate,
      erzet                  as CreatedAtTime,
      _Item
}
```

### Object 1b — Interface CDS view (item) `ZI_GatePassItem`
```cds
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Gate Pass - Interface (item)'
@Metadata.allowExtensions: true
define view entity ZI_GatePassItem
  as select from zgp_item
  association        to parent ZI_GatePass     as _GatePass on  $projection.GpNumber  = _GatePass.GpNumber
                                                            and $projection.FiscalYear = _GatePass.FiscalYear
  association [0..*] to ZI_GatePassPart        as _Part     on  $projection.GpNumber  = _Part.GpNumber
                                                            and $projection.ItemNumber = _Part.ItemNumber
{
  key gpnum                  as GpNumber,
  key zitem                  as ItemNumber,
  key mjahr                  as FiscalYear,
      matnr                  as Material,
      maktx                  as MaterialDescription,
      lifnr                  as Supplier,
      name1                  as SupplierName,
      @Semantics.quantity.unitOfMeasure: 'Unit'
      gp_quan                as Quantity,
      @Semantics.unitOfMeasure: true
      gp_meins               as Unit,
      _GatePass,
      _Part
}
```

### Object 1c — Interface CDS view (associated part) `ZI_GatePassPart`
```cds
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Gate Pass - Interface (inward receipt part)'
@Metadata.allowExtensions: true
define view entity ZI_GatePassPart
  as select from zgp_part
{
  key gpnum                  as GpNumber,
  key zitem                  as ItemNumber,
  key cnt                    as PartCount,
      rec_quan               as ReceivedQuantity,
      vbill_no               as BillingDocument,
      vbill_dt               as BillingDate,
      mat_stat               as MaterialStatus
}
```

### Object 2a — Projection view (header) `ZC_GatePass`
```cds
@EndUserText.label: 'Gate Pass - Projection (header)'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['GpNumber', 'FiscalYear']
define root view entity ZC_GatePass
  provider contract transactional_query
  as projection on ZI_GatePass
{
      @Search.defaultSearchElement: true
  key GpNumber,
  key FiscalYear,
      DocumentType,
      Plant,
      Department,
      VehicleNumber,
      InDate,
      InTime,
      OutDate,
      OutTime,
      Remarks,
      CreatedByUser,
      CreatedBy,
      CreatedOnDate,
      CreatedAtTime,
      _Item : redirected to composition child ZC_GatePassItem
}
```

### Object 2b — Projection view (item) `ZC_GatePassItem`
```cds
@EndUserText.label: 'Gate Pass - Projection (item)'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity ZC_GatePassItem
  as projection on ZI_GatePassItem
{
  key GpNumber,
  key ItemNumber,
  key FiscalYear,
      Material,
      MaterialDescription,
      Supplier,
      SupplierName,
      Quantity,
      Unit,
      _GatePass : redirected to parent ZC_GatePass,
      _Part     : redirected to ZC_GatePassPart
}
```

### Object 2c — Projection view (associated part) `ZC_GatePassPart`
```cds
@EndUserText.label: 'Gate Pass - Projection (inward receipt part)'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity ZC_GatePassPart
  as projection on ZI_GatePassPart
{
  key GpNumber,
  key ItemNumber,
  key PartCount,
      ReceivedQuantity,
      BillingDocument,
      BillingDate,
      MaterialStatus
}
```

### Object 3a — Metadata extension (header) `ZC_GatePass`
```cds
@Metadata.layer: #CORE
@UI: { headerInfo: { typeName: 'Gate Pass', typeNamePlural: 'Gate Passes',
  title: { type: #STANDARD, value: 'GpNumber' },
  description: { type: #STANDARD, value: 'VehicleNumber' } } }
annotate view ZC_GatePass with
{
  @UI.facet: [
    { id: 'General', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'General', position: 10 },
    { id: 'Items',   purpose: #STANDARD, type: #LINEITEM_REFERENCE, label: 'Items',
      position: 20, targetElement: '_Item' }
  ]
  @UI: { lineItem: [ { position: 10 } ], identification: [ { position: 10 } ], selectionField: [ { position: 10 } ] }
  @EndUserText.label: 'Gate Pass No.'
  GpNumber;
  @UI: { lineItem: [ { position: 20 } ], identification: [ { position: 20 } ], selectionField: [ { position: 20 } ] }
  @EndUserText.label: 'Fiscal Year'
  FiscalYear;
  @UI: { lineItem: [ { position: 30 } ], identification: [ { position: 30 } ], selectionField: [ { position: 30 } ] }
  @EndUserText.label: 'Doc Type'
  DocumentType;
  @UI: { lineItem: [ { position: 40 } ], identification: [ { position: 40 } ], selectionField: [ { position: 40 } ] }
  @EndUserText.label: 'Plant'
  Plant;
  @UI: { lineItem: [ { position: 50 } ], identification: [ { position: 50 } ] }
  @EndUserText.label: 'Department'
  Department;
  @UI: { lineItem: [ { position: 60 } ], identification: [ { position: 60 } ] }
  @EndUserText.label: 'Vehicle No.'
  VehicleNumber;
  @UI: { lineItem: [ { position: 70 } ], identification: [ { position: 70 } ] }
  @EndUserText.label: 'In Date'
  InDate;
  @UI: { identification: [ { position: 80 } ] }
  @EndUserText.label: 'In Time'
  InTime;
  @UI: { lineItem: [ { position: 90 } ], identification: [ { position: 90 } ] }
  @EndUserText.label: 'Out Date'
  OutDate;
  @UI: { identification: [ { position: 100 } ] }
  @EndUserText.label: 'Out Time'
  OutTime;
  @UI: { identification: [ { position: 110 } ] }
  @EndUserText.label: 'Remarks'
  Remarks;
}
```

### Object 3b — Metadata extension (item) `ZC_GatePassItem`
```cds
@Metadata.layer: #CORE
annotate view ZC_GatePassItem with
{
  @UI.facet: [ { id: 'ItemGeneral', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'Item', position: 10 } ]
  @UI: { lineItem: [ { position: 10 } ], identification: [ { position: 10 } ] }
  @EndUserText.label: 'Item'
  ItemNumber;
  @UI: { lineItem: [ { position: 20 } ], identification: [ { position: 20 } ] }
  @EndUserText.label: 'Material'
  Material;
  @UI: { lineItem: [ { position: 30 } ], identification: [ { position: 30 } ] }
  @EndUserText.label: 'Description'
  MaterialDescription;
  @UI: { lineItem: [ { position: 40 } ], identification: [ { position: 40 } ] }
  @EndUserText.label: 'Supplier'
  Supplier;
  @UI: { lineItem: [ { position: 50 } ], identification: [ { position: 50 } ] }
  @EndUserText.label: 'Supplier Name'
  SupplierName;
  @UI: { lineItem: [ { position: 60 } ], identification: [ { position: 60 } ] }
  @EndUserText.label: 'Quantity'
  Quantity;
  @UI: { lineItem: [ { position: 70 } ], identification: [ { position: 70 } ] }
  @EndUserText.label: 'Unit'
  Unit;
}
```

### Object 4 — Interface behavior definition `ZI_GatePass` (simplified, class-free; header + item)
```abap
managed;

define behavior for ZI_GatePass alias GatePass
persistent table zgp_hdr
lock master
{
  create;
  update;
  delete;
  association _Item { create; }

  field ( readonly ) CreatedBy, CreatedOnDate, CreatedAtTime, CreatedByUser;
  field ( mandatory : create ) DocumentType, Plant;

  mapping for zgp_hdr
  {
    GpNumber       = gpnum;
    FiscalYear     = mjahr;
    DocumentType   = dtype;
    Plant          = werks;
    Department     = dept;
    VehicleNumber  = vhnum;
    InDate         = gindat;
    InTime         = gintme;
    OutDate        = gotdat;
    OutTime        = gottme;
    Remarks        = remks;
    CreatedByUser  = cre_user;
    CreatedBy      = ernam;
    CreatedOnDate  = erdat;
    CreatedAtTime  = erzet;
  }
}

define behavior for ZI_GatePassItem alias GatePassItem
persistent table zgp_item
lock dependent by _GatePass
{
  update;
  delete;
  field ( readonly ) GpNumber, FiscalYear;
  field ( mandatory : create ) Material, Quantity;
  association _GatePass;

  mapping for zgp_item
  {
    GpNumber            = gpnum;
    ItemNumber          = zitem;
    FiscalYear          = mjahr;
    Material            = matnr;
    MaterialDescription = maktx;
    Supplier            = lifnr;
    SupplierName        = name1;
    Quantity            = gp_quan;
    Unit                = gp_meins;
  }
}
```

### Object 5 — Projection behavior definition `ZC_GatePass` (header + item)
```abap
projection;

define behavior for ZC_GatePass alias GatePass
{
  use create;
  use update;
  use delete;
  use association _Item { create; }
}

define behavior for ZC_GatePassItem alias GatePassItem
{
  use update;
  use delete;
  use association _GatePass;
}
```

### Object 6 — Service definition `ZUI_GATEPASS`
```cds
@EndUserText.label: 'Gate Pass Service'
define service ZUI_GATEPASS {
  expose ZC_GatePass     as GatePass;
  expose ZC_GatePassItem as GatePassItem;
  expose ZC_GatePassPart as GatePassPart;
}
```

### Object 7 — Service binding
Create via wizard: Name `ZUI_GATEPASS_O4`, Binding Type **OData V4 - UI**, Service Definition `ZUI_GATEPASS`; then Activate + Publish.

---
