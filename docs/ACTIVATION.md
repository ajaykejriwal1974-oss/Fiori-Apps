# Activation ↔ Extension — how the Basis runbook and this repo fit together

Source: `KEJRIWAL_Fiori_Activation_Runbook.pdf` (S/4HANA 2025, quality system
**KSQ/KHQ**, **client 500**). That runbook is the **Basis** side — it *activates*
the standard and base Fiori apps. This repo is the **Dev** side — it *extends*
the base apps. They are complementary and must run in the right order.

## Order of operations (important)

```
1. Basis: apply the SP/FPS stack          (runbook §1)
2. Basis: SAP Fiori Rapid Activation       (runbook §2 - STC01 task lists)
       SAP_FIORI_FOUNDATION_SETUP  (once)
       SAP_FIORI_CONTENT_ACTIVATION (once per business role below)
   -> activates each base app's OData service + business catalog + SICF node
3. Dev:  fill REPLACE_WITH_* placeholders against the now-live base apps
       (component id, extension points, BSP name) via BAS Adaptation Editor
4. Dev:  deploy the extensions / custom apps (npm run deploy -> FES BSP)
5. Dev/Basis: publish each app's FLP tile + assign role (docs/PUBLISHING.md)
```

> Our extensions cannot be deployed or previewed until step 2 has activated the
> **base** app — an adaptation project references the live base component, and a
> custom app binds the live (or new custom) OData service.

## System coordinates (from the runbook)

- System: `192.168.0.21:8002` (FLP: `/sap/bc/ui2/flp?sap-client=500`)
- Client: **500** (the `ui5.yaml` files use client `500`; the URL stays a
  `REPLACE_WITH_ABAP_SYSTEM_URL` placeholder, set it per developer/destination).
- Current state at runbook generation: only 320 OData services active — the
  target apps are **not yet activated**.

## Base app → business role → repo artifact

The runbook activates the base app under a business role; this repo provides the
"extend later" development. Assign the role in PFCG (runbook §2.3 / §5).

| Base app | App ID | Business role to activate | Repo artifact |
|---|---|---|---|
| Confirm Production Operation | F3069 | `SAP_BR_PRODN_OPERATOR` | [confirm-production-operation-ext](../apps/confirm-production-operation-ext) |
| Create / Manage Sales Orders | F1873 | `SAP_BR_INTERNAL_SALES_REP` | [manage-sales-orders-ext](../apps/manage-sales-orders-ext) (incl. ZSOCLOSE) |
| Manage Sales Contracts (status/rate) | VA42 / verify | `SAP_BR_INTERNAL_SALES_REP` | [manage-sales-contracts-ext](../apps/manage-sales-contracts-ext) |
| Manage Sales Contracts (mass batch) | VA42 / verify | `SAP_BR_INTERNAL_SALES_REP` | [contract-batch-update](../apps/contract-batch-update) |
| Manage Outbound Deliveries | F0867A | `SAP_BR_SHIPPING_SPECIALIST` | [manage-outbound-deliveries-ext](../apps/manage-outbound-deliveries-ext) |
| Record Inspection Results | F2655 (verify) | `SAP_BR_QUALITY_TECHNICIAN` | [record-inspection-results-mass](../apps/record-inspection-results-mass) |
| Post Goods Movement | MIGO / verify | `SAP_BR_INVENTORY_MANAGER` | [post-goods-movement-hu](../apps/post-goods-movement-hu) |
| Pack (Handling Unit Mgmt) | HUMO / VL02N | `SAP_BR_WAREHOUSE_CLERK` | [dyeing-packing](../apps/dyeing-packing) |
| Shade master (no standard app) | — | — (key-user / RAP) | [backend/shade-master-rap](../backend/shade-master-rap) |

> Custom apps (inspection results, goods movement, packing, contract batch
> update) expose **new** OData services — those are activated when the custom RAP
> service / app variant is deployed, not by the standard Rapid Activation roles.
> The role above is who should get the tile.

## Table A — activate only, no development

Runbook §3 (replace as-is) needs no repo artifact — activate and assign the role:
Manage Batches (F2462), Manage Credit Cases (UKM_MY_DCDS), Manage Credit/Debit
Memo Requests (F1989/F1988), Manage Journal Entries (F0717), Display Line Items
in G/L (F2217), Manage Customer Line Items (F0711 verify), Reprocess Bank
Statement Items (F1520), Compare Supplier Quotations (F2324), Manage Product
Master (F1602), Post Acquisition (ABZON verify).

## Verification (runbook §5)

- `/IWFND/MAINT_SERVICE` — role's OData services show green; ICF nodes active.
- `/IWFND/ERROR_LOG` — no activation errors.
- Active-service count rises well above 320
  (`SELECT COUNT(*) FROM "/IWFND/C_MGDEAM"`).
- PFCG — catalog/group in the role; role assigned to a test user.
- FLP smoke test at `/sap/bc/ui2/flp?sap-client=500`.

> Do **not** run this in PROD until validated in KSQ and the SP stack is applied.
