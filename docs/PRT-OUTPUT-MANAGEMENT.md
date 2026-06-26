# PRT layer — 61 print/form programs → S/4HANA Output Management

The **61 `PRT` tcodes** in [CLASSIFICATION.md](CLASSIFICATION.md#prt--print--output--output-management-adobe--smartforms-61)
are print / form drivers. None is a tile of its own. They re-platform onto
**SAP S/4HANA Output Management (OM)** — the clean-core successor to the old
`SAPscript`/`Smart Forms` + `NACE` condition records:

- **Determination** → BRF+ output parameter determination (replaces `NACE`/`TNAPR`).
- **Form** → a **Form Template** (Adobe / Fiori *Maintain Form Templates*) bound
  to the object's form data model (replaces the Z SAPscript/Smart Form).
- **Channel** → Print / Email / EDI / XML, per receiver via *Output Parameter
  Determination* (Fiori) + *Maintain Print Queues* / *Output Management* apps.

> One form template + one BRF+ decision per **output object** usually replaces a
> whole cluster of Z drivers (e.g. all the "print invoice" variants → one
> Billing Document template with conditions). Build the **template + condition**,
> not 61 programs.

## 1. Billing / invoice / export & statutory forms (13)
Output object **Billing Document** (`BILLING_DOCUMENT`); role `SAP_BR_BILLING_CLERK`.

| Z tcode | Z program | What | OM target |
|---|---|---|---|
| ZINVC / ZINVCN | ZRPT_SD_005_NEW(_P_GST) | GST tax invoice (multi/print) | Billing Document → Invoice template; **e-invoice via DRC** |
| ZBILLGP | ZSOL_BILL_GATEPASS | Billing gate pass | Billing Document → additional template/channel |
| ZBRC | ZRPT_SD_BRCPRINT | Export invoice (BRC) | Billing Document (export) template |
| ZEXP | ZRPT_EXIM | EXIM form | Billing Document (export) / foreign-trade template |
| ZRETINV / ZRETINVN | ZPRG_MM_006 / ZMM_RETINV | Return (excise) invoice | Billing Document (returns) template |
| ZF201A / ZF201AN | ZRPT_SD_FORM201A(_NEW) | Form 201A | **Assess — pre-GST excise register** (see note) |
| ZF201B / ZF201BN | ZRPT_PREG_IPL_* | Purchase register / 201B | **Assess — pre-GST** (GST purchase register / GSTR-2) |
| ZF201C / ZF201CN | ZRPT_MM_F201C(_ALV) | Form 201C | **Assess — pre-GST** |

> **GST note:** the Form 201A/B/C and excise return forms are **pre-GST excise
> registers**. Under GST they are largely obsolete — statutory output now flows
> through **GST returns + SAP DRC** (e-invoice / e-way bill, the excluded DRC
> layer). Confirm with finance before rebuilding any 201-series form; most retire.

## 2. Sales order & delivery forms (5)
Output objects **Sales Order** / **Outbound Delivery**; roles
`SAP_BR_INTERNAL_SALES_REP`, `SAP_BR_SHIPPING_SPECIALIST`.

| Z tcode | Z program | What | OM target |
|---|---|---|---|
| ZORDER | ZRPT_PP_CALLSF_002 | Order print | Sales Order → Order Confirmation template |
| ZORDERN | ZRPT_PP_ORDER_NEW | Sales order form | Sales Order → Order Confirmation template |
| ZPACK | ZPACKING_LIST | Packing list | Outbound Delivery → Packing List template |
| ZPLISTP | ZPACKING_LIST | Packing list (print) | Outbound Delivery → Packing List template |
| ZPRINT_TO | ZTO_FORM_DRIVER | LT31 transfer-order printout | Warehouse / EWM TO print (or OM delivery template) |

## 3. Gate Pass (20) — custom output object
There is **no standard SAP gate pass**, so this stays custom — but split it:

- **Form/print** drivers → an **Adobe Form Template** printed from the gate-pass
  app via OM-style determination on a *custom* output object.
- **Entry** transactions (`ZGPS01/02/03`, `ZGPSI1/2/3`, `ZGP`, `ZGATE`,
  `ZGATEENTRY`) are **data capture**, not print → **✅ built** as a managed RAP
  composition (header → item over `ZGP_HDR`/`ZGP_ITEM`) in
  [`backend/gate-pass-rap`](../backend/gate-pass-rap); the form is its output.
- **Reports** (`ZGATER`, `ZGATERE`, `ZGATENR`, `ZGREPT*`, `ZGATEPASS_REPT`,
  `ZGPASS`) → CDS analytical queries over the gate-pass table (BI layer), not forms.

| Sub-group | Z tcodes | Target |
|---|---|---|
| Entry (returnable/non-ret, inward/outward) | ZGP, ZGPS01/02/03, ZGPSI1/2/3, ZGATE, ZGATEENTRY, ZGATEPLANT | Custom RAP capture app (managed BO) |
| Print / driver | ZGPASS, ZGATEPASS, ZREPASS | Custom Adobe form template (custom OM object) |
| Reports | ZGATER, ZGATERE, ZGATENR, ZGREPT, ZGREPTNE, ZGREPTRE, ZGATEPASS_REPT | CDS query → analytics (Route BI) |

> **Built:** the entry capture is now [`backend/gate-pass-rap`](../backend/gate-pass-rap)
> — a managed RAP composition over `ZGP_HDR`/`ZGP_ITEM` (the `ZGPS*`/`ZGPSI*`
> model). `ZGP_PART` (inward receipts) is associated read-only pending a data-model
> fix (no `MJAHR` key). The print/driver and report rows above still route to OM /
> analytics respectively.

## 4. Labels / barcode / stickers (10)
No native S/4 label engine — use an **OM form template with barcode fields**
(Code128/QR via Adobe barcode UDFs) routed to the label printer, or a certified
label channel (ZPL/direct). Reuse one label template parameterised by type.

| Z tcode | Z program | What |
|---|---|---|
| ZBARGR | ZSOL_PO_GR_BARCODE | Barcode GR print |
| ZBOXPRT | ZSOL_BARCODE_STICKER | Box barcode sticker |
| ZSBAR | ZSOL_BARCODE_LABEL | Barcode label |
| ZSTICKER | ZDRIVER_STICKER | Sticker print |
| ZLABEL | SAPMZ_PP_LABEL_001 | Label master maintenance *(see note)* |
| ZPAL_PRINT | ZSOL_PP_SLIP_BARCODE | Pallet no. on barcode |
| ZPAL_REPRINT | ZSOL_PAL_REPRINT | Pallet label reprint |
| ZREPRINT | ZCRPG_PP_SLIP | Box slip reprint |
| ZREPRINTPLT | ZCRPG_PP_SLIP_BIGPLT | Big-pallet label reprint |
| ZREPRINTR | ZCRPT_PP_003 | Reprint report |

> `ZLABEL` (label *master* maintenance) is a small master, not a form — model it
> as a tiny managed-RAP master (or reuse the **Packing Material** master) if the
> label layout/type list must be maintained.

## 5. Finance forms (4)
| Z tcode | Z program | What | OM / standard target | Role |
|---|---|---|---|---|
| ZCHQ | ZRPT_FI_CHQ | Cheque printing | **Check Management** (Payment Medium / `RFFOUS_C`, DMEE) | `SAP_BR_AP_ACCOUNTANT` |
| ZPSLIP / ZPSLIPN | ZRPT_RCPT_VCHR(_NEW) | Bank receipt voucher | FI correspondence / OM form on the payment document | `SAP_BR_AP_ACCOUNTANT` |
| ZREPSLIP | ZRPT_RCPT_VCHR_VIEW | View receipt voucher | Display payment + reprint correspondence | `SAP_BR_AP_ACCOUNTANT` |

## 6. Production / QM / MM forms (6)
| Z tcode | Z program | What | OM target |
|---|---|---|---|
| ZRECP / ZRECPN | ZRPT_PP_SSF_RECEIPE | Print recipe master | Adobe template printed from the **Recipe Master** app (`backend/recipe-master-rap`) |
| ZREJOB / ZREJOBN | ZRPT_PP_REJOB(N) | Print job card | Adobe template printed from the **Job Master** app (`backend/job-master-rap`) |
| ZQ_FORM | ZQM_PROGRAM | QM form | Output object **Inspection** / quality certificate template |
| ZMAT_PRINT | ZSOLS_MM_MAT_ISSUE_SLIP | Material issue slip | Material Document / goods-issue OM template |

> The recipe / job-card prints are the **output side** of masters we already
> built — add a form template to those apps, don't write a print program.

## 7. Not actually forms — re-route (3)
| Z tcode | Z program | Reality | Route |
|---|---|---|---|
| ZMBR / ZMBR1 / ZMBRCR | — | "Maintain BRC Exc. Rate & Date" — **maintenance**, not print | Small config/master (exchange-rate table) or reuse standard currency exchange rates (`OB08` / *Manage Exchange Rates*) |

## Migration procedure (per output object, not per program)
1. **Group** the Z drivers by output object (the tables above) — one template
   replaces the whole cluster.
2. **Build the Form Template** (Fiori *Maintain Form Templates*, Adobe) on the
   object's form data model; recreate the Z layout, reusing the custom append
   fields (`ZZ…`) already on the document.
3. **Configure determination** in BRF+ (*Output Parameter Determination*):
   receiver, channel (print/email/EDI), printer/queue, copies — replacing the
   `NACE` condition records.
4. **Assign** the *Output Items*/*Manage Print Queues* apps to the relevant
   `SAP_BR_*` role; test print on the FES.
5. **Retire** the Z driver and its SAPscript/Smart Form after a parallel run.

## Net
61 `PRT` programs → a **handful of OM form templates + BRF+ determinations** on
standard objects, plus: gate pass (custom object — optional `gate-pass-rap`
build), labels (template + label channel), and 3 non-form items rerouted. The
pre-GST 201-series forms are flagged to **retire under GST/DRC**, not rebuild.
