# Fiori Apps – KEJRIWAL extensions

Clean-core SAP Fiori extensions for the S/4HANA 2025 migration, derived from
`KEJRIWAL_Z_to_Fiori_Mapping.pdf`. Each standard app that needs customization
(Table B of the mapping) gets its own **SAPUI5 Adaptation Project** under
`apps/`, layering custom fields / sections / controller logic on top of the
delivered app **without modifying SAP source**.

## Principle

- **Table A** apps (12) → adopt the standard Fiori app as-is, no development
  (activate OData service + assign business catalog/role + retrain). Nothing to
  build here.
- **Table B** apps (10) → adopt the standard app, then re-add the customization
  the clean-core way: key-user / in-app extensibility, custom CDS, or a released
  BAdI / RAP extension — never a modification.

## Apps in this repo

| App | Fiori ID | Replaces (Z) | Status |
|---|---|---|---|
| [Manage Sales Orders](apps/manage-sales-orders-ext) | F1873 | ZVA01 / ZVA01N, ZSOCLOSE | Scaffolded (UI layer; placeholders to complete on live system) |
| [Confirm Production Operation](apps/confirm-production-operation-ext) | F3069 | ZCO11N / ZCO11A | Scaffolded (UI layer; placeholders to complete on live system) |
| [Manage Outbound Deliveries](apps/manage-outbound-deliveries-ext) | F0867A | ZDEL | Scaffolded (UI layer; challan print via Output Management) |

> Remaining Table B candidates to scaffold next on request: F2655 (Record
> Inspection Results), MIGO/HU goods movement, Manage Sales Contracts
> (close/release/rate), HU packing, and the ZDD_SHADE Custom Business Object
> (RAP, not an adaptation project).

## Layout

```
apps/
  manage-sales-orders-ext/      # F1873 adaptation project
    webapp/
      manifest.appdescr_variant # app-variant descriptor
      changes/
        fragments/              # custom XML UI sections
        coding/                 # controller extensions
        manifest/               # page-configuration / column changes
        annotations/            # (optional) annotation changes
      i18n/
    ui5.yaml
    package.json
```

Each project's own README lists the `REPLACE_WITH_*` placeholders that must be
filled from the live system and the backend (CDS / RAP / BAdI) prerequisites.
