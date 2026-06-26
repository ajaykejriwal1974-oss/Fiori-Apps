# KEJRIWAL Z-portfolio — authoritative tcode classification & build routing

Source: the per-tcode classification map (`tcode, classification, program, description, n_ztables, ztables`). **This file supersedes the heuristic routing in `ROUTE7-PLAN.md`** — the classification column is authoritative.

**285 transactions** across **7 classes**. Counts:

| Class | Meaning | Count |
|---|---|---:|
| `CUS` | Custom transactional / master — build (RAP / Fiori Elements / freestyle) | 72 |
| `EXT` | Extend standard — adaptation project or unmanaged service over standard | 19 |
| `STD` | Use STANDARD Fiori app — retire the Z program | 17 |
| `BI` | Report / analytics — route to the analytical layer | 87 |
| `PRT` | Print / output — Output Management (Adobe / SmartForms) | 61 |
| `UPL` | Upload / automation utility — data migration or job | 28 |
| `RET` | Retire | 1 |

> **Clean core throughout** — every route below either reuses a standard app, extends it without modification, or builds a *new* custom object that touches only its own custom tables. No standard SAP object is modified.

## `CUS` — Custom transactional / master — build (RAP / Fiori Elements / freestyle)  (72)

Genuine custom logic with no standard equivalent. Build as managed RAP (masters) or unmanaged RAP / freestyle (transactional). DRC items excluded.

| Tcode | Program | Description | Custom tables |
|---|---|---|---|
| `ZBANK` | ZSOL_BANK_BALANCE | bank balance | — |
| `ZBATCHD` | ZPP_BATCH_DELETE | Batch Deletion | `ZPP_BATCH` `ZPP_SCHEDULE` `ZPP_SHADE` |
| `ZBATCH_CLS` | ZSOL_WIP_BATCH_CLOSE | Batch close transaction | `ZPP_BATCHN` `ZPP_PACK` `ZZMARA` |
| `ZBOE` | — | Bill of Exchange | — |
| `ZCFORM1` | — | CFORM MASTER | — |
| `ZDELC` | ZSOL_DELIVERY_CHALLAN | Delivery Challan | `ZPP_PACK` `ZZLIKP` |
| `ZDIGI` | — | Maintaince for Digital Signature | — |
| `ZDSP_CORR` | ZSOL_DISPATCH_CORRECTION | Dispatch correction | `ZPP_PACK` `ZSOL_HUDISPATCH` `ZVBAP` |
| `ZEINV` | ZEINV_COCKPIT | E-Invoice and E-Way Bill Cockpit | — |
| `ZEINV_CANC` | ZEINV_CANC | E-Invoice and E-Way Bill cancel | `ZEINV_AUDITLOG` `ZEINV_LOGIN` `ZEXTSTA` `ZKIL_VBRK` `ZZGATEPASS` |
| `ZEINV_CO_CODE` | — | Company Code | — |
| `ZEINV_DOCTYP` | — | Document Type | — |
| `ZEINV_EWAY_BY_IRN` | ZEINV_EWAY_USING_IRN | Create E-Way Bill using IRN | `ZDE_TRCODE` `ZDE_TRDESC` `ZEINV_AUDITLOG` `ZEINV_LOGIN` `ZKIL_VBRK` `ZTRPTMSTR` `ZZGATE…` |
| `ZEINV_EXT` | ZEINV_EXTRACT | E-Invoice and E-Way Bill Extract | — |
| `ZEINV_LOGIN` | — | Login | — |
| `ZEINV_SETUP` | ZEXIM_COCKPIT_NEW | E-Invoice Setup Cockpit | — |
| `ZEINV_STATE_CODE` | — | State Code | — |
| `ZEINV_UOM` | — | UOM | — |
| `ZEINV_UPDATE` | ZEINV_EBILL_UPDDATE | Update IRN and EWB NO from excel | `ZEINV_AUDITLOG` `ZEINV_CO_CODE` `ZKIL_VBRK` `ZZGATEPASS` |
| `ZEINV_UPGRADE` | ZEINV_UPDATE_PROGRAM | Update program for fiscal year | — |
| `ZEWAY_CANC` | ZEWAY_CANC | E-Way Bill Cancellation | `ZEINV_AUDITLOG` `ZEINV_LOGIN` `ZEXTSTA` `ZKIL_VBRK` `ZZGATEPASS` |
| `ZEXN` | — | Maintain Custom Invoice Number | — |
| `ZFORM` | ZCFORM1 | ZFORM FOR PENDING AND RECEIVE | `ZCFORM1` `ZCFORM2` `ZKIL_VBRK` `ZSF_FORM` `ZZGATEPASS` |
| `ZFORMS` | ZCFORM | ZCFORM | `ZCFORM1` `ZCFORM2` `ZKIL_VBRK` `ZZGATEPASS` |
| `ZGISLIP` | ZREPT_MM_R001 | goods reciept slip | — |
| `ZHUINB` | ZSOL_INBOUND_HU | HU's in inbound delivery | — |
| `ZHUINV` | ZSOL_MTOS_PROCESS | Physical inventroy document create | `ZHUINV_HDR` `ZHUINV_ITEM` `ZPP_GRADE` `ZPP_PACK` `ZVBAP` `ZZMARA` |
| `ZHUPK` | ZSOL_INW_HU_UNPACK | RM unpack transaction | `ZPP_PACK` `ZSOL_AUTH` `ZSOL_HULG` |
| `ZINSPLOT` | — | Maintaince for Inspection lot | — |
| `ZJOB01` | SAPMZ_PP_JOB_CARD | Create : Job Master | `ZPP_BATCH` `ZPP_SCHEDULE` `ZPP_SHADE` `ZVBAP` |
| `ZJOB01N` | SAPMZ_PP_JOB_CARDN | Create : Job Master | `ZDE_PENQTY` `ZDE_TOTBTCH` `ZPP_BATCHN` `ZPP_JOBN` `ZPP_PACK` `ZPP_SCHEDULEN` `ZPP_SHADE…` |
| `ZJOB02` | SAPMZ_PP_JOB_CARD | Change : Job Master | `ZPP_BATCH` `ZPP_SCHEDULE` `ZPP_SHADE` `ZVBAP` |
| `ZJOB02N` | SAPMZ_PP_JOB_CARDN | Change : Job Master | `ZDE_PENQTY` `ZDE_TOTBTCH` `ZPP_BATCHN` `ZPP_JOBN` `ZPP_PACK` `ZPP_SCHEDULEN` `ZPP_SHADE…` |
| `ZJOB03` | SAPMZ_PP_JOB_CARD | Display : Job Master | `ZPP_BATCH` `ZPP_SCHEDULE` `ZPP_SHADE` `ZVBAP` |
| `ZJOB03N` | SAPMZ_PP_JOB_CARDN | Display : Job Master | `ZDE_PENQTY` `ZDE_TOTBTCH` `ZPP_BATCHN` `ZPP_JOBN` `ZPP_PACK` `ZPP_SCHEDULEN` `ZPP_SHADE…` |
| `ZMBR2` | — | Maintain Export Details | — |
| `ZMERGE` | — | Maintain Merge Details | — |
| `ZMINMAX` | ZSOL_MIN_MAX | Maximum Minimum | `ZZMARA` |
| `ZPACK01` | ZPP_PACK_MODULE_NEW | Create: Packing Details | `ZMM_MARA` `ZMM_SHADE` `ZPACK_MAST` `ZPP_BAG` `ZPP_BOX` `ZPP_COTTON` `ZPP_END` `ZPP_GRAD…` |
| `ZPACK01N` | ZPP_PACK_MODULE | Packing Details | `ZMM_MARA` `ZPP_BAG` `ZPP_BOX` `ZPP_COTTON` `ZPP_END` `ZPP_GRADE` `ZPP_HUNUM` `ZPP_MAS` …` |
| `ZPACK02` | ZPP_PACK_MODULE_NEW | Change: Packing Details | `ZMM_MARA` `ZMM_SHADE` `ZPACK_MAST` `ZPP_BAG` `ZPP_BOX` `ZPP_COTTON` `ZPP_END` `ZPP_GRAD…` |
| `ZPACK02N` | SAPMZ_PP_001 | Change : Packing Details | `ZPP_PACK` `ZPP_PCBY` |
| `ZPACK03` | ZPP_PACK_MODULE_NEW | Display: Packing Details | `ZMM_MARA` `ZMM_SHADE` `ZPACK_MAST` `ZPP_BAG` `ZPP_BOX` `ZPP_COTTON` `ZPP_END` `ZPP_GRAD…` |
| `ZPACK_MAST` | — | for material | — |
| `ZPALLET` | ZPP_HU_CREATE | Pack: Boxes on Pallet | `ZPP_HUNUM` `ZPP_PACK` `ZPP_PALET` |
| `ZPALLET1` | ZPP_PALLET_POST | Sales:Pallet Packing | — |
| `ZPAL_BOX` | ZSOL_PALLETIZATION | T-code for Palletization cockpit | `ZBOXNO` `ZDE_GCODE` `ZPAL_CONT` `ZPAL_HEAD` `ZPAL_PACK` `ZPP_PACK` `ZSOLGETBOXES` `ZSOL…` |
| `ZPC01` | ZSOL_STDVSACT_COST | Standard vs Actual | `ZZMARA` |
| `ZPCBY` | — | Maintain Checked/Packed By Details | — |
| `ZPCFORM` | ZCFORM2 | ZCFORM2 T-CODE | `ZCFORM1` `ZCFORM2` `ZKIL_VBRK` `ZZGATEPASS` |
| `ZPDF` | RSTXPDFT4 | Converting Spool job to PDF | — |
| `ZPOST01` | ZPP_PACK_POST | Posting: Packing and GR | `ZMELT` `ZPACK_MAST` `ZPAL_CONT` `ZPAL_HEAD` `ZPP_BATCHN` `ZPP_PACK` `ZPP_PTYP` `ZZMARA` |
| `ZQAR` | RQEVAC50 | Cancel Inspection Lot | — |
| `ZRECP01` | SAPMZ_PP_COMPONENT | Create : Receipe Master | `ZPP_BATCH` `ZPP_COMP` `ZPP_RECEIPE` `ZPP_SHADE` |
| `ZRECP02` | SAPMZ_PP_COMPONENT | Change : Receipe Master | `ZPP_BATCH` `ZPP_COMP` `ZPP_RECEIPE` `ZPP_SHADE` |
| `ZRECP03` | SAPMZ_PP_COMPONENT | Display : Receipe Master | `ZPP_BATCH` `ZPP_COMP` `ZPP_RECEIPE` `ZPP_SHADE` |
| `ZREPACK` | ZPP_PACK_MODULE_NEW | Repack: Packing Details | `ZMM_MARA` `ZMM_SHADE` `ZPACK_MAST` `ZPP_BAG` `ZPP_BOX` `ZPP_COTTON` `ZPP_END` `ZPP_GRAD…` |
| `ZSCH01` | SAPMZ_PP_SCHEDULE | Create : Schedule Details | `ZPP_SCHEDULE` `ZPP_SHADE` `ZPP_SHNUM` `ZVBAP` |
| `ZSCH01N` | SAPMZ_PP_SCHEDULEN | Create : Schedule Details | `ZPP_JOBN` `ZPP_SCHEDULEN` `ZPP_SHADE` `ZPP_SHNUM` `ZVBAP` |
| `ZSCH02` | SAPMZ_PP_SCHEDULE | Change : Schedule Details | `ZPP_SCHEDULE` `ZPP_SHADE` `ZPP_SHNUM` `ZVBAP` |
| `ZSCH02N` | SAPMZ_PP_SCHEDULEN | Change : Schedule Details | `ZPP_JOBN` `ZPP_SCHEDULEN` `ZPP_SHADE` `ZPP_SHNUM` `ZVBAP` |
| `ZSCH03` | SAPMZ_PP_SCHEDULE | Display : Schedule Details | `ZPP_SCHEDULE` `ZPP_SHADE` `ZPP_SHNUM` `ZVBAP` |
| `ZSCH03N` | SAPMZ_PP_SCHEDULEN | Display : Schedule Details | `ZPP_JOBN` `ZPP_SCHEDULEN` `ZPP_SHADE` `ZPP_SHNUM` `ZVBAP` |
| `ZSOL_ACCGRP` | SAPLZSOL_DASH | Maintain Account Grouping | `ZSOL_ACCGRP` `ZSOL_ACC_GRP` `ZSOL_PRDPLAN` |
| `ZSOL_ASRS` | ZSOL_UPDATE_PALLET | tcode for zsol_update pallet | `ZPAL_HEAD` |
| `ZSOL_AUTOPAY` | ZSOL_AUTOPAYTR | PAYMENT PROPOSAL CHANGE | — |
| `ZTRANS` | — | Maintain Transport Code | — |
| `ZTRUCK` | — | Truck Master | — |
| `ZVFORM` | ZSOL_VFORM1 | vendor invoice | `ZKIL_VBRK` `ZVFORM2` `ZZGATEPASS` |
| `ZVFORMS` | ZSOL_VFORM | allocate vendor invoice | `ZVFORM2` |
| `ZWIP` | ZPRD_ORDER_STATUS | PRD Material Order Status | — |
| `ZZFBL2N` | ZZFBL2N | ZZFBL2N | `ZKIL` `ZZRFPOSX` |

## `EXT` — Extend standard — adaptation project or unmanaged service over standard  (19)

Standard process with custom add-ons. Extend the standard Fiori app (adaptation / key-user) or wrap standard BAPIs in an unmanaged service. Never modify standard objects.

| Tcode | Program | Description | Custom tables |
|---|---|---|---|
| `ZBATCH_CHANGE` | ZSOL_SALE_ORDER_BATCH_UPDATE | Contract Batch Update | `ZVBAP` `ZZMARA` |
| `ZBOX_MOVE` | ZSOL_POST_GOODS_MOVEMENTS | Post goods Movement | — |
| `ZCO11A` | SAPMZ_PP_CO11N | Dying : Production Entry | `ZPP_BATCHN` `ZPP_JOBN` `ZZMARA` |
| `ZCO11N` | SAPMZ_PP_CONFIRMATION | Dying : Production Entry | `ZPP_BATCH` `ZPP_SCHEDULE` `ZVBAP` |
| `ZCON02` | ZSD_RPT_PCONTRACT_REG_PCON | update Rate of pending contract | `ZDE_GCODE` `ZDE_LRNO` `ZDE_PKREM` `ZDE_SIZE` `ZDE_TPM` `ZGATEPASS` `ZMM_SHADE` `ZPP_GRA…` |
| `ZCON_CLOSE` | ZSOL_CONTRACT_CLOSE | Contract Close | `ZVBAP` `ZZMARA` |
| `ZCON_CLOSE1` | ZSOL_CONTRACT_CLOSE_ONE | Completed Contract Close | `ZGATEPASS` `ZVBAP` `ZZMARA` |
| `ZCOREL` | ZSOL_CONTRACT_RELEASE | Contrract Release | `ZZMARA` |
| `ZDD_SHADE` | — | Shade Master - Dope Dyeing | — |
| `ZDEL` | ZRPT_DELIVERY_CHALLAN | Outbound Delivery | `ZGATEPASS` `ZZLIKP` |
| `ZPACK01D` | ZPP_PACK_MODULE_DYING | Create: Packing Details | `ZMM_MARA` `ZPP_BAG` `ZPP_BATCHN` `ZPP_BOX` `ZPP_COTTON` `ZPP_END` `ZPP_GRADE` `ZPP_GSIZ…` |
| `ZPACK02D` | ZPP_PACK_MODULE_DYING | Create: Packing Details | `ZMM_MARA` `ZPP_BAG` `ZPP_BATCHN` `ZPP_BOX` `ZPP_COTTON` `ZPP_END` `ZPP_GRADE` `ZPP_GSIZ…` |
| `ZPACK03D` | ZPP_PACK_MODULE_DYING | Create: Packing Details | `ZMM_MARA` `ZPP_BAG` `ZPP_BATCHN` `ZPP_BOX` `ZPP_COTTON` `ZPP_END` `ZPP_GRADE` `ZPP_GSIZ…` |
| `ZQA32` | ZQM_MASS_RESULT2 | QA32 Mass Result Recording | `ZINSPLOT_QA32` |
| `ZREPACKD` | ZPP_PACK_MODULE_DYING | Repack Open Stock | `ZMM_MARA` `ZPP_BAG` `ZPP_BATCHN` `ZPP_BOX` `ZPP_COTTON` `ZPP_END` `ZPP_GRADE` `ZPP_GSIZ…` |
| `ZSOCLOSE` | ZSOL_SALESORDER_CLOSE | Sales order close | `ZVBAP` |
| `ZSOCLOSE1` | ZSOL_SO_CLOSE | Sales Order Close Program | `ZDE_DESCR` `ZDE_GCODE` `ZDE_LRNO` `ZDE_PKREM` `ZDE_SIZE` `ZDE_TPM` `ZGATEPASS` `ZMM_SHA…` |
| `ZVA01` | SAPMZ_SO_CREATE | Sales: Create Sales Order | `ZBAPEX_VBAP` `ZBAPE_VBAP` `ZPP_BATCH` `ZPP_GRADE` `ZPP_SCHEDULE` `ZPP_SHADE` `ZPP_SIZE`…` |
| `ZVA01N` | SAPMZ_SO_CREATEN | Sales: Create Sales Order | `ZBAPEX_VBAP` `ZBAPE_VBAP` `ZPP_BATCHN` `ZPP_GRADE` `ZPP_JOBN` `ZPP_SCHEDULEN` `ZPP_SHAD…` |

## `STD` — Use STANDARD Fiori app — retire the Z program  (17)

A standard S/4HANA Fiori app already covers this. Map the user to the standard app + Fiori role; retire the custom transaction.

| Tcode | Program | Description | Custom tables |
|---|---|---|---|
| `ZBATCH01` | SAPMZ_PP_BATCH | Create : Batch Master | `ZPP_BATCH` `ZPP_BTNUM` `ZPP_PACK` `ZPP_SCHEDULE` |
| `ZBATCH01N` | SAPMZ_PP_BATCHN | Create : Batch Master | `ZPP_BATCHN` `ZPP_BTNUM` `ZPP_JOBN` |
| `ZBATCH02` | SAPMZ_PP_BATCH | Change : Batch Master | `ZPP_BATCH` `ZPP_BTNUM` `ZPP_PACK` `ZPP_SCHEDULE` |
| `ZBATCH02N` | SAPMZ_PP_BATCHN | Change : Batch Master | `ZPP_BATCHN` `ZPP_BTNUM` `ZPP_JOBN` |
| `ZBATCH03` | SAPMZ_PP_BATCH | Display : Batch Master | `ZPP_BATCH` `ZPP_BTNUM` `ZPP_PACK` `ZPP_SCHEDULE` |
| `ZBATCH03N` | SAPMZ_PP_BATCHN | Display : Batch Master | `ZPP_BATCHN` `ZPP_BTNUM` `ZPP_JOBN` |
| `ZCM_RELEASE` | ZSOL_REMOVE_CREDITBLOCK | Credit release | `ZSOL_CM_SGM` |
| `ZCRDRNOTE` | ZCRPT_FI_R001 | Credit Debit Note | — |
| `ZF90` | ZRPT_FI_BDC_F90 | Asset Purchase | — |
| `ZFB03` | ZCRPT_FI_R003 | Print Voucher | — |
| `ZFBL3N` | ZSOLS_FI_GL_LINE_DISP | GL Line Item Display | — |
| `ZFBL5N` | ZSOL_CUSTOMER_REPORT | Customer Report | — |
| `ZFF67` | ZCBDC_FI_FF67_N1 | Manual Account Statement | — |
| `ZME49` | ZRM06EPS0 | Price Comparison List | — |
| `ZMM60` | ZMAT_LIST | Material List | `ZZMARA` |
| `ZZFBL3N` | ZZFBLN3 | G/L Account Line Items | `ZKIL` `ZVBAP` `ZZRFPOSX` |
| `ZZFBL5N` | ZZFBL5N | Customer Line Item Display | `ZKIL` `ZZRFPOSX` |

## `BI` — Report / analytics — route to the analytical layer  (87)

Reporting only. Re-platform as CDS analytical queries / Embedded Analytics or the external BI layer (Metabase). Not a transactional app.

| Tcode | Program | Description | Custom tables |
|---|---|---|---|
| `ZACTUAL` | ZSOLS_STD_ACTUAL_COST | Standard Vs Actual Report | `ZZMARA` |
| `ZASTOCK` | Z_MATERIAL_LEDGER | zastock(ztest) | `ZZMARA` |
| `ZAUDIT_LOG` | ZAUDIT_LOG | Audit Log Report | `ZEINV_AUDITLOG` `ZEXDAT` `ZEXTBY` `ZEXTSTA` `ZKIL_VBRK` `ZZGATEPASS` |
| `ZBATCH_WIP` | ZSOL_WIP_BATCH | WIP batch report | `ZPP_BATCHN` |
| `ZBOXSTOCK` | ZPP_BOXWISE_STOCK | Box wise Stock Report | `ZMM_SHADE` `ZPAL_CONT` `ZPP_BATCHN` `ZPP_END` `ZPP_GRADE` `ZPP_JOBN` `ZPP_MERGE` `ZPP_P…` |
| `ZBSTOCK` | Z_MATERIAL_LEDGER_BATCH | Batch Wise Stock Report | `ZZMARA` |
| `ZCDQD` | ZRPT_FI_002 | Posting for CD,QD,RD,Interest & TDS | `ZKIL_VBRK` `ZZGATEPASS` |
| `ZCMM001` | ZCRPT_MM_005 | Stock Report (MM) | — |
| `ZCOMM` | ZRPT_FI_AGTCOMMISSION | Commission Report | `ZKIL_VBRK` `ZTB_FI_COMMITM` `ZZGATEPASS` |
| `ZCRDRPN` | ZRPT_FI_CRDR | Credit/Debit Note (ALV) | — |
| `ZCRP` | ZCUST_RET_PACK_AGE_REP | Customer Returnable Packaging Report | `ZMATDOC_KNVP` |
| `ZCSD001` | ZCRPT_SD_002 | Unassign Boxes for Returns Delivery | `ZGATEPASS` `ZPP_PACK` `ZZLIKP` `ZZMARA` |
| `ZCUST` | ZCUST_ERPSLS_CUSTOMERS | ALV REPORT FOR ZCUST | — |
| `ZDISPATCH` | ZDISPATCH_SECURITY_RPT | Dispatch Security Function. Report | `ZPP_PACK` `ZZLIKP` |
| `ZDSTOCK` | ZSD_RPT_DSTOCK | dyeing stock | `ZGATEPASS` `ZPP_BATCH` `ZPP_BATCHN` `ZPP_GRADE` `ZPP_JOBN` `ZPP_PACK` `ZPP_SCHEDULE` `Z…` |
| `ZFI005` | ZRPT_FI_CUST_AGEING | Customer Ageing Analysis Report | `ZKIL_VBRK` `ZZGATEPASS` |
| `ZFI007` | ZRPT_FI_VEND_AGEING | Vendor Ageing Analysis Rep | — |
| `ZFI007T` | ZRPT_FI_VEND_AGEING_T | Vendor Ageing Analysis Report | — |
| `ZFICAG` | ZRPT_FI_AGING | Debtors Ageing Analysis as on Date | — |
| `ZFICSR` | ZFI_CUST_STATEMENT | Customer Account Statement | `ZKIL_VBRK` `ZZGATEPASS` |
| `ZFIGSR` | ZFI_GL_STATEMENT | G/L Account Statement | — |
| `ZFINT` | ZRPT_FI_001_NEW_PRG1 | Interest Report | — |
| `ZFINT1` | ZRPT_INTRPT_NEW | Interest Report | `ZKIL_VBRK` `ZZGATEPASS` |
| `ZFIVSR` | ZFI_VEND_STATEMENT | Vendor Account Statement | `ZKIL_VBRK` `ZZGATEPASS` |
| `ZFI_TDS` | ZFI_RPT_TDS | Vendor and Customer TDS Report | — |
| `ZGCUDB` | ZRPT_SD_EXPORT | Goods Cleared Under Depb Scheme | `ZEXP` `ZKIL_VBRK` `ZSD_BRC` `ZSD_BRC1` `ZSD_CUSTOM` `ZZGATEPASS` `ZZLIKP` |
| `ZGST` | ZFI_GST_TAX_REPORT | Tcode for tax report | `ZSOL_GST_DET` |
| `ZGST1` | ZFI_GST_TAX_R | Tcode for Tax Report | `ZKIL_VBRK` `ZSOL_GST_DET` `ZZGATEPASS` |
| `ZGST2` | ZFI_GST_TAX__NEW | Tcode for Tax Report | `ZKIL_VBRK` `ZSOL_GST_DET` `ZZGATEPASS` |
| `ZGSTCR` | ZSOL_FI_GST_TAX_R | Tax Report | `ZKIL_VBRK` `ZSOL_GST_DET` `ZZGATEPASS` |
| `ZGSTOCK` | ZGRADE_STOCK | grade vice stock report | `ZMM_SHADE` `ZPP_END` `ZPP_GRADE` `ZPP_PACK` `ZPP_PTYP` `ZZLIKP` `ZZMARA` |
| `ZHUINV_CLS` | ZSOL_PHYHU_CLOSE | HU Inventory Report | `ZHUINV_HDR` `ZHUINV_ITEM` |
| `ZHUMO` | ZCRPT_PP_002 | HU Monitor | `ZPP_GRADE` `ZPP_PACK` `ZPP_PTYP` `ZZLIKP` `ZZMARA` |
| `ZHUREC` | ZSOL_HU_RECO | HU Reconilation Report | `ZPP_PACK` |
| `ZINVC_DS` | ZRPT_SD_005_DS | Commercial Invoice with Digital Sign | `ZFIELD` `ZKIL_VBRK` `ZTDIGI_SIGN` `ZTRPTMSTR` `ZZGATEPASS` `ZZLIKP` |
| `ZJOBREPORT` | ZRPT_PP_JOB | Job Card Master Report | `ZPP_BATCH` `ZPP_SCHEDULE` `ZPP_SHADE` |
| `ZJOBREPTN` | ZRPT_PP_JOBCARD | Job Card Master Report ( New ) | `ZPP_BATCHN` `ZPP_JOBN` `ZPP_SCHEDULEN` `ZPP_SHADE` |
| `ZJWCHLN` | ZCRPT_MM_R01 | Job-Work Challan | `ZCTA_MM_JOB` |
| `ZMB5B` | ZZRM07MLBD | Stock Summary | `ZZMARA` |
| `ZMC46` | ZSOL_SLOW_STOCK | Slow moving stock | `ZZMARA` |
| `ZMTOS` | ZSOL_MTOS_PROCESS | Transfer MTO to MTS stock | `ZHUINV_HDR` `ZHUINV_ITEM` `ZPP_GRADE` `ZPP_PACK` `ZVBAP` `ZZMARA` |
| `ZPACKLIST` | ZSD_PACKING_REPORT | Sales: Packing Report | `ZKIL_VBRK` `ZPP_PACK` `ZVBAP` `ZZGATEPASS` `ZZLIKP` |
| `ZPACKLIST01` | ZSALES_DOC_POST | Sales: Create Packing List | `ZKIL_VBRK` `ZPP_PACK` `ZVBAP` `ZZGATEPASS` `ZZLIKP` |
| `ZPACKLISTN` | ZSALES_DOC_POST_01 | Sales: Create Packing List | `ZGATEPASS` `ZKIL_VBRK` `ZPP_BATCH` `ZPP_JOBN` `ZPP_PACK` `ZPP_SCHEDULE` `ZPP_SCHEDULEN`…` |
| `ZPCON` | ZSD_RPT_PCONTRACT_REG_N | Pending Contract Register | `ZDE_GCODE` `ZDE_LRNO` `ZDE_PKREM` `ZDE_SIZE` `ZDE_TPM` `ZGATEPASS` `ZMM_SHADE` `ZPP_GRA…` |
| `ZPCOND` | ZSD_RPT_PCONTRACT_REG_P | contract | `ZDE_GCODE` `ZDE_LRNO` `ZDE_PKREM` `ZDE_SIZE` `ZDE_TPM` `ZGATEPASS` `ZMM_SHADE` `ZPP_GRA…` |
| `ZPCONS` | ZSD_RPT_PCONTRACT_REG_H | Pending Contract Schedule | `ZDE_GCODE` `ZDE_LRNO` `ZDE_PKREM` `ZDE_SIZE` `ZDE_TPM` `ZGATEPASS` `ZMM_SHADE` `ZPP_GRA…` |
| `ZPCON_CP` | ZSD_RPT_PCONTRACT_REG_N_COPY | copy of pcon | `ZDE_GCODE` `ZDE_LRNO` `ZDE_PKREM` `ZDE_SIZE` `ZDE_TPM` `ZGATEPASS` `ZMM_SHADE` `ZPP_GRA…` |
| `ZPDESP` | ZSD_RPT_PDESP_REG | Pending Dispach Register | `ZDE_DESCR` `ZDE_GCODE` `ZDE_LRNO` `ZDE_PKREM` `ZDE_SIZE` `ZDE_TPM` `ZGATEPASS` `ZMM_SHA…` |
| `ZPEL` | ZSOL_PALLET_STOCK | pallet report | `ZKIL_VBRK` `ZPP_PACK` `ZZGATEPASS` `ZZMARA` |
| `ZPLIST01` | ZSD_PACKING_LIST_01 | Sales: Create Packing List | — |
| `ZPLIST01A` | ZSD_PACKING_LIST_IPL | Sales: Create Packing List | `ZMS_PALET` `ZPALNO` `ZPAL_CONT` `ZPAL_HEAD` `ZPLISTD` `ZPP_PACK` `ZPP_PTYP` `ZPP_SIZE` …` |
| `ZPLIST01T` | ZSD_PACKING_LIST_HSM | Sales: Create Packing List | — |
| `ZPLIST02` | ZSD_PACKING_LIST_01 | Sales: Change Packing List | — |
| `ZPLIST02A` | ZSD_PACKING_LIST_IPL | Sales: Change Packing List | `ZMS_PALET` `ZPALNO` `ZPAL_CONT` `ZPAL_HEAD` `ZPLISTD` `ZPP_PACK` `ZPP_PTYP` `ZPP_SIZE` …` |
| `ZPLIST02N` | ZSD_PACKING_LIST_N | SALES PACKAGING LIST | — |
| `ZPLIST02T` | ZSD_PACKING_LIST_HSM | Sales: Change Packing List | — |
| `ZPLIST03` | ZSD_PACKING_LIST_01 | Sales: Display Packing List | — |
| `ZPLIST03A` | ZSD_PACKING_LIST_IPL | Sales: Display Packing List | `ZMS_PALET` `ZPALNO` `ZPAL_CONT` `ZPAL_HEAD` `ZPLISTD` `ZPP_PACK` `ZPP_PTYP` `ZPP_SIZE` …` |
| `ZPLIST03N` | ZSD_PACKING_LIST_N | SALES PACKAGING LIST | — |
| `ZPLIST03T` | ZSD_PACKING_LIST_HSM | Sales: Display Packing List | — |
| `ZPLISTD` | ZSD_PACKING_LIST_01 | Sales: Delete Packing List | — |
| `ZPLISTDA` | ZSD_PACKING_LIST_IPL | Sales: Delete Packing List | `ZMS_PALET` `ZPALNO` `ZPAL_CONT` `ZPAL_HEAD` `ZPLISTD` `ZPP_PACK` `ZPP_PTYP` `ZPP_SIZE` …` |
| `ZPLISTDT` | ZSD_PACKING_LIST_HSM | Sales: Delete Packing List | — |
| `ZPOCLOSE` | ZCRPT_MM_004 | PO Close | — |
| `ZPO_CLOSE` | ZSOL_PO_CLOSURE | PO Close Report | — |
| `ZPR` | ZRPT_PR | Purchase Requisition | `ZLT_EBAN` `ZTT_EBAN` `ZTT_PRN` `ZZMARA` |
| `ZPRP` | ZRPT_PP_001 | Packed Boxes Report | `ZGATEPASS` `ZMM_SHADE` `ZPAL_CONT` `ZPP_BATCHN` `ZPP_GRADE` `ZPP_JOBN` `ZPP_MERGE` `ZPP…` |
| `ZPRP1` | ZGRADE_STOCK_PER | grade vice stock report with per | `ZMM_SHADE` `ZPP_END` `ZPP_GRADE` `ZPP_PACK` `ZPP_PTYP` `ZZMARA` |
| `ZPRPSZ` | ZRPT_PP_002 | Size wise production report | `ZGATEPASS` `ZPP_BATCHN` `ZPP_GRADE` `ZPP_JOBN` `ZPP_PACK` `ZPP_PCBY` `ZPP_PTYP` `ZPP_SC…` |
| `ZPUREG` | ZRPT_PREG_IPL | Purchase Register | `ZKIL_VBRK` `ZSOL_GST_DET` `ZZGATEPASS` `ZZMARA` |
| `ZPWDIS` | ZSD_SALES_RPT_SCHWISE | Schedule Wise Dispatch | `ZGATEPASS` `ZKIL_VBRK` `ZPP_BATCH` `ZPP_BATCHN` `ZPP_GRADE` `ZPP_JOBN` `ZPP_PACK` `ZPP_…` |
| `ZQTDS` | ZRPT_FI_INMIS | TDS Quarterly Report | — |
| `ZRECPM` | ZSOL_RECIPE_MASTER | recipe matser report | `ZKIL_VBRK` `ZPP_BATCH` `ZPP_BATCHN` `ZPP_CAPACITY` `ZPP_COMP` `ZPP_JOBN` `ZPP_RECEIPE` …` |
| `ZRFQ` | ZRPT_RFQ | Request For Quotation | `ZLT_EKKO` `ZTT_EKKO` |
| `ZRG1` | ZRG_REGISTER | RG 1 Register | `ZKIL_VBRK` `ZMM_CLSTOCK` `ZPP_PACK` `ZZGATEPASS` `ZZMARA` |
| `ZRG1N` | ZRG_REGISTER_02 | RG 1 Register | `ZKIL_VBRK` `ZMM_CLSTOCK` `ZPP_PACK` `ZZGATEPASS` `ZZMARA` |
| `ZRG1TEX` | ZRG_REGISTER_2001 | RG1 Register - Tex. Division | `ZKIL_VBRK` `ZMM_CLSTOCK` `ZMM_OPSTOCK` `ZPP_PACK` `ZZGATEPASS` `ZZMARA` |
| `ZSALES` | ZCRPT_SD_001 | Sales Report | — |
| `ZSALESB` | ZSD_SALES_RPT_NEW_TT | Sales register with individual batch | `ZEINV_AUDITLOG` `ZGATEPASS` `ZKIL_VBRK` `ZPP_BATCH` `ZPP_BATCHN` `ZPP_GRADE` `ZPP_JOBN`…` |
| `ZSALESMAIL` | ZSALESN_MAIL | Auto MAIL Sales report | `ZFIELD` `ZGATEPASS` `ZKIL_VBRK` `ZPP_BATCH` `ZPP_BATCHN` `ZPP_GRADE` `ZPP_JOBN` `ZPP_PA…` |
| `ZSALESN` | ZSD_SALES_RPT_NEW | Sales Report | `ZEINV_AUDITLOG` `ZGATEPASS` `ZKIL_VBRK` `ZPP_BATCH` `ZPP_BATCHN` `ZPP_GRADE` `ZPP_JOBN`…` |
| `ZSCAND` | ZRPT_SALES_SCAN | Dowload Markup and Stock Files | `ZGATEPASS` `ZKIL_VBRK` `ZMM_SHADE` `ZPAL_CONT` `ZPP_BATCH` `ZPP_END` `ZPP_GRADE` `ZPP_P…` |
| `ZSOREG` | ZRPT_SALES_001 | Sales : Order Register | `ZGATEPASS` `ZKIL_VBRK` `ZPP_GRADE` `ZPP_PACK` `ZSDTOL` `ZVBAP` `ZZGATEPASS` `ZZLIKP` |
| `ZSSTOCK` | ZCRPT_SD_T_STOCK | T-CODE FOR SIZE STOCK REPORT | `ZMM_SHADE` `ZPP_END` `ZPP_GRADE` `ZPP_MERGE` `ZPP_PACK` `ZPP_PTYP` `ZZMARA` |
| `ZSTOCK` | ZRPT_MM_STKSMRY | Stock Summary Report | `ZBOXNO` `ZDE_DESCR` `ZDE_GCODE` `ZDE_GDESC` `ZDE_SHDCD` `ZDE_TPM` `ZMM_SHADE` `ZNETWT` …` |
| `ZTASKLIST` | ZSOL_TASKLIST_CREATE | Task List create report | — |

## `PRT` — Print / output — Output Management (Adobe / SmartForms)  (61)

Form or print program. Re-implement via SAP Output Management (BRF+ / Adobe Forms / form templates). Not a tile of its own.

| Tcode | Program | Description | Custom tables |
|---|---|---|---|
| `ZBARGR` | ZSOL_PO_GR_BARCODE | Barcode GR Print | — |
| `ZBILLGP` | ZSOL_BILL_GATEPASS | Billing Gate Pass | `ZKIL_VBRK` `ZSOL_BILL_GATEP` `ZZGATEPASS` |
| `ZBOXPRT` | ZSOL_BARCODE_STICKER | BARCODE STICKER | — |
| `ZBRC` | ZRPT_SD_BRCPRINT | Export Invoice BRC | `ZKIL_VBRK` `ZZGATEPASS` |
| `ZCHQ` | ZRPT_FI_CHQ | Cheque Printint | — |
| `ZEXP` | ZRPT_EXIM | EXIM Form Printing | `ZKIL_VBRK` `ZZGATEPASS` |
| `ZF201A` | ZRPT_SD_FORM201A | Form 201A | `ZKIL_VBRK` `ZZGATEPASS` |
| `ZF201AN` | ZRPT_SD_FORM201A_NEW | Form 201A(ALV) | — |
| `ZF201B` | ZRPT_PREG_IPL_FORM | Purchase Register Form | — |
| `ZF201BN` | ZRPT_PREG_IPL_ZF201B | Form 201B (ALV) | — |
| `ZF201C` | ZRPT_MM_F201C | Form 201C | `ZST_MARA` `ZZMARA` |
| `ZF201CN` | ZRPT_MM_F201C_ALV | Form 201C(ALV) | `ZZMARA` |
| `ZGATE` | SAPLZGPASS | Gate Pass New | `ZGATEPASS` `ZMM_GPHDR` `ZMM_GPITEM` `ZMM_GPREC` `ZMM_GTNUM` `ZZMARA` |
| `ZGATEENTRY` | SAPLZFG_GATEPASS | Gate Pass Inward | `ZGATEPASS` `ZGATEPASS_HDR` `ZGATEPASS_ITEM` `ZGATEPASS_PLANT` `ZKIL_VBRK` `ZMM_GPHDR` `…` |
| `ZGATENR` | ZCRPT_MM_003 | Non Returnable Gate Pass Report | `ZMM_GPHDR` `ZMM_GPITEM` `ZMM_GPREC` |
| `ZGATEPASS` | ZRPT_GATEPASS | Report: Gate Pass | `ZKIL_VBRK` `ZTB_GATE_DTL` `ZTB_GATE_MSTR` `ZTB_TRUCK_MSTR` `ZZGATEPASS` `ZZLIKP` |
| `ZGATEPASS_REPT` | ZGATEPASS_REPORT | Gate Pass Report | `ZGATEPASS_HDR` `ZGATEPASS_ITEM` |
| `ZGATEPLANT` | — | Maintaince for Gate Pass Plant | — |
| `ZGATER` | ZCRPT_MM_001 | Gate Pass Report | — |
| `ZGATERE` | ZCRPT_MM_002 | Returnable Gate Pass Report | `ZMM_GPHDR` `ZMM_GPITEM` `ZMM_GPREC` |
| `ZGP` | SAPMZ_GATE_PASS | Gate Pass Application | `ZDE_DOCUNO` `ZDE_REMARKS` `ZGATEPASS` `ZTB_GATE_DTL` `ZTB_GATE_MSTR` `ZTRCKMSTR` `ZZLIKP` |
| `ZGPASS` | ZGATEPASS_OUT | Print Gate Pass | `ZGATEPASS` `ZGT_PASS` `ZPP_PACK` `ZTB_GATE_DTL` `ZTB_GATE_MSTR` `ZTB_TRUCK_MSTR` `ZTRANS` |
| `ZGPS01` | SAPMZ_MM_GATEPASS | Create : Gate Pass Entry | `ZGPASS_NUM` `ZGP_HDR` `ZGP_ITEM` `ZZMARA` |
| `ZGPS02` | SAPMZ_MM_GATEPASS | Change : Gate Pass Entry | `ZGPASS_NUM` `ZGP_HDR` `ZGP_ITEM` `ZZMARA` |
| `ZGPS03` | SAPMZ_MM_GATEPASS | Display : Gate Pass Entry | `ZGPASS_NUM` `ZGP_HDR` `ZGP_ITEM` `ZZMARA` |
| `ZGPSI1` | SAPMZ_MM_GATEPASS_IN | Create : Gate Pass Entry In | `ZGPASS_NUM` `ZGP_HDR` `ZGP_ITEM` `ZGP_PART` |
| `ZGPSI2` | SAPMZ_MM_GATEPASS_IN | Change : Gate Pass Entry In | `ZGPASS_NUM` `ZGP_HDR` `ZGP_ITEM` `ZGP_PART` |
| `ZGPSI3` | SAPMZ_MM_GATEPASS_IN | Display : Gate Pass Entry In | `ZGPASS_NUM` `ZGP_HDR` `ZGP_ITEM` `ZGP_PART` |
| `ZGREPT` | ZCRPT_ENTRY_REPT | Gate Pass Report | — |
| `ZGREPTNE` | ZCRPT_GATEPASS_ENTRY_NON_RET | Non-Returnable Gate Pass Report | `ZGP_HDR` `ZGP_ITEM` |
| `ZGREPTRE` | ZCRPT_GATEPASS_ENTRY | Returnable Gate Pass Report | `ZGP_HDR` `ZGP_ITEM` `ZGP_PART` |
| `ZINVC` | ZRPT_SD_005_NEW | Multiple Invoice print | `ZFIELD` `ZKIL_VBRK` `ZZGATEPASS` |
| `ZINVCN` | ZRPT_SD_005_NEW_P_GST | print invoice | `ZFIELD` `ZKIL_VBRK` `ZTRPTMSTR` `ZZGATEPASS` `ZZLIKP` |
| `ZLABEL` | SAPMZ_PP_LABEL_001 | Maintain Label Master | `ZPP_LABEL` |
| `ZMAT_PRINT` | ZSOLS_MM_MAT_ISSUE_SLIP | Material Issue Print | — |
| `ZMBR` | — | Maintain BRC Exc. Rate & Date | — |
| `ZMBR1` | — | Maintain BRC Exc. Rate & Date | — |
| `ZMBRCR` | — | Maintain BRC Exc. Rate & Date | — |
| `ZORDER` | ZRPT_PP_CALLSF_002 | Order Print | — |
| `ZORDERN` | ZRPT_PP_ORDER_NEW | Sales Order Form | `ZVBAP` |
| `ZPACK` | ZPACKING_LIST | Sales Print Packing List | `ZPP_PACK` `ZVBAP` |
| `ZPAL_PRINT` | ZSOL_PP_SLIP_BARCODE | pallet no print on barcode | `ZPAL_CONT` `ZPAL_HEAD` `ZPP_PACK` `ZSOL_REPRINT` |
| `ZPAL_REPRINT` | ZSOL_PAL_REPRINT | Palletization Label Reprint | `ZPAL_CONT` `ZPAL_PACK` `ZSOL_PACK_ST` `ZSOL_PACK_TT` |
| `ZPLISTP` | ZPACKING_LIST | Sales: Print Packing list | `ZPP_PACK` `ZVBAP` |
| `ZPRINT_TO` | ZTO_FORM_DRIVER | LT31 FORM Printout | `ZTO_STR` |
| `ZPSLIP` | ZRPT_RCPT_VCHR | Print Bank Receipt Voucher | `ZBANK` |
| `ZPSLIPN` | ZRPT_RCPT_VCHR_NEW | Print Bank Receipt Voucher | `ZBANK` |
| `ZQ_FORM` | ZQM_PROGRAM | Form | `ZINSPLOT_QA32` `ZQM_STRUCT` `ZQM_STRUCT_PLMK` |
| `ZRECP` | ZRPT_PP_SSF_RECEIPE | Print Receipe Master | `ZPP_BATCH` `ZPP_BATCHN` `ZPP_JOBN` `ZPP_RECEIPE` `ZPP_SCHEDULEN` |
| `ZRECPN` | ZRPT_PP_SSF_RECEIPE | Print Receipe Master | `ZPP_BATCH` `ZPP_BATCHN` `ZPP_JOBN` `ZPP_RECEIPE` `ZPP_SCHEDULEN` |
| `ZREJOB` | ZRPT_PP_REJOB | Print Job Card Master | `ZPP_BATCH` |
| `ZREJOBN` | ZRPT_PP_REJOBN | Print Job Card Master | `ZPP_JOBN` |
| `ZREPASS` | ZMM_DRIVER_PGM_GATE_PASS | Return/Non-returnable Gate Pass | `ZGP_HDR` `ZGP_ITEM` |
| `ZREPRINT` | ZCRPG_PP_SLIP | zreprint | `ZPP_PACK` `ZSOL_REPRINT` `ZZMARA` |
| `ZREPRINTPLT` | ZCRPG_PP_SLIP_BIGPLT | Reprint Pallet Label | `ZPP_PACK` `ZZMARA` |
| `ZREPRINTR` | ZCRPT_PP_003 | ZREPRINT Report | `ZREPRINT` |
| `ZREPSLIP` | ZRPT_RCPT_VCHR_VIEW | View Bank Receipt Voucher | `ZBANK` |
| `ZRETINV` | ZPRG_MM_006 | Print Return Excise Invoice | — |
| `ZRETINVN` | ZMM_RETINV | Return Invoice Print | — |
| `ZSBAR` | ZSOL_BARCODE_LABEL | Barcode print | `ZPP_PACK` `ZROLL` `ZSOLOPENORD` `ZZMARA` |
| `ZSTICKER` | ZDRIVER_STICKER | STICKER PRINT | — |

## `UPL` — Upload / automation utility — data migration or job  (28)

Mass upload / automation program. Re-platform via Migration Cockpit, LTMC, or a scheduled job / API — not an interactive Fiori app.

| Tcode | Program | Description | Custom tables |
|---|---|---|---|
| `ZABMA` | ZFI_ABMA_BAPI_ASSET_UPLOAD | Tcode for asset upload | — |
| `ZAUTOPO` | ZPRG_PO_CREATE | Create PO Automation | `ZGATEPASS` `ZKIL_VBRK` `ZMM_AUTOPO` `ZZGATEPASS` `ZZLIKP` `ZZMARA` |
| `ZAUTOPO8` | ZPRG_PO_CREATE_8000 | Auto Po create | `ZGATEPASS` `ZKIL_VBRK` `ZMM_AUTOPO` `ZZGATEPASS` `ZZLIKP` `ZZMARA` |
| `ZAUTOPOG` | ZPRG_PO_CREATE_6000 | AUTOPO  for 6000 | `ZGATEPASS` `ZKIL_VBRK` `ZMM_AUTOPO` `ZZGATEPASS` `ZZLIKP` `ZZMARA` |
| `ZAUTOPOJ` | ZPRG_PO_CREATE_7000 | AUTOPO  for 7000 | `ZGATEPASS` `ZKIL_VBRK` `ZMM_AUTOPO` `ZZGATEPASS` `ZZLIKP` `ZZMARA` |
| `ZAUTOPOM` | ZPRG_PO_CREATE_NEW | Create PO Automation new | `ZGATEPASS` `ZKIL_VBRK` `ZMM_AUTOPO` `ZZGATEPASS` `ZZLIKP` `ZZMARA` |
| `ZAUTOPOM1` | ZPRG_PO_CREATE_NEW1 | Auto Po Creation | `ZGATEPASS` `ZKIL_VBRK` `ZMM_AUTOPO` `ZZGATEPASS` `ZZLIKP` `ZZMARA` |
| `ZAUTOPON` | ZPRG_PO_CREATEN | Create New PO Automation | `ZGATEPASS` `ZKIL_VBRK` `ZMM_AUTOPO` `ZSOL_AUPO` `ZZGATEPASS` `ZZLIKP` `ZZMARA` |
| `ZAUTOPOS` | ZPRG_PO_CREATE_5000 | Auto po Create | `ZGATEPASS` `ZKIL_VBRK` `ZMM_AUTOPO` `ZZGATEPASS` `ZZLIKP` `ZZMARA` |
| `ZBANK_VEND` | ZSOL_VEND_BANK_CHANG | Vendor Bank details upload pgm | — |
| `ZEINV_UPLOAD` | ZEINV_UPLOAD | Upload Program using IRN | — |
| `ZF02` | ZRFI_BAPI_ACC_DOC_POST | Bapi acc doc post | — |
| `ZFIBRC` | ZFI_BANK_CLEAR | Bank Reconciliation Automation | — |
| `ZFICOI` | ZBDC_FI_OPEN_C_V | BDC for customer open item | — |
| `ZFIEX` | ZRPT_BDC_F02 | BDC for f-02 | — |
| `ZFIGOI` | ZBDC_FI_GL_OP | GL Open items | — |
| `ZFIOP` | ZPRG_BDC_COI | Upload Vendor Open Items | — |
| `ZFIVT` | ZRPT_BDC_F02_NEW | BDC for f-02 Vendor | — |
| `ZHU_UNPACK` | ZSOL_BAPI_HU_UNPACK | Unpacking an Item from an HU 8000 CC | `ZPP_PACK` |
| `ZIA01` | ZEQUIPMENT_TASK_UPLOAD | EQUIPMENT TASK UPLOAD | — |
| `ZSAL_POST` | ZFI_BAPI_F_02 | upload program for f-02 | — |
| `ZSCANU` | ZRPT_SALES_UPLOAD | Scan Upload | `ZPP_PACK` `ZSDTOL` `ZVBAP` |
| `ZSDOBD` | ZSD_OBD_AUTOMATION | Sales: OBD Automation | `ZPP_PACK` `ZPP_PTYP` `ZSOL_621MSG` `ZSOL_HUDISPATCH` `ZSOL_LOCKDIS` `ZTB_TRUCK_MSTR` `Z…` |
| `ZSDOBDN` | ZSD_OBD_AUTOMATION_NEW | Sales: OBD Automation new | `ZGATEPASS` `ZPP_PACK` `ZPP_PTYP` `ZSOL_621MSG` `ZSOL_HUDISPATCH` `ZSOL_LOCKDIS` `ZTB_TR…` |
| `ZV2` | ZCBDC_SD_VA02_001 | VA02 Update | `ZVBAP` |
| `ZVK11` | ZPRG_BDC_VK11 | Upload Create Condition Records | `ZKOMPAZ` |
| `ZVLMOVE` | ZSOL_VLMOVE_BAPI | VLMOVE BAPI | `ZZMARA` |
| `ZWMTO_UPLD` | ZWM_TRANSFER_ORDER_UPLOAD | Transfer Order with Mat.Doc Upload | — |

## `RET` — Retire  (1)

Obsolete — retire.

| Tcode | Program | Description | Custom tables |
|---|---|---|---|
| `ZJ1IIN` | ZSD_EXCISE_AUTOMATE | Automatic Excise Invoice Creation | `ZKIL_VBRK` `ZZGATEPASS` |

## How the custom builds in this repo map to the `CUS` / `EXT` rows

| This repo | Class | Tcodes covered | Backed by |
|---|---|---|---|
| `backend/recipe-master-rap` | CUS | ZRECP01/02/03 | managed RAP over `ZPP_RECEIPE` |
| `backend/job-master-rap` | CUS | ZJOB01/02/03(N) | managed RAP over `ZPP_JOBN` |
| `backend/schedule-master-rap` | CUS | ZSCH01/02/03(N) | managed RAP over `ZPP_SCHEDULEN` |
| `backend/transport-code-master-rap` | CUS | ZTRANS | managed RAP over `ZTRANS` |
| `backend/truck-master-rap` | CUS | ZTRUCK | managed RAP over `ZTB_TRUCK_MSTR` |
| `backend/merge-master-rap` | CUS | ZMERGE | managed RAP over `ZPP_MERGE` |
| `backend/checked-by-master-rap` | CUS | ZPCBY | managed RAP over `ZPP_PCBY` |
| `backend/packing-material-master-rap` | CUS | ZPACK_MAST | managed RAP over `ZPACK_MAST` |
| `backend/export-detail-master-rap` | CUS | ZMBR2 | managed RAP over `ZEXP` |
| `backend/digital-signature-master-rap` | CUS | ZDIGI | managed RAP over `ZTDIGI_SIGN` |
| `backend/minmax-master-rap` | CUS→STD | ZMINMAX | **reuse standard MRP** (`MARC` min/max) — no custom table |
| `backend/packing-detail-rap` | CUS | ZPACK01/02/03(+N), ZREPACK | unmanaged RAP → BAPI_HU_PACK / reuse `ZSOL_PACK_CDS` |
| `backend/palletization-rap` | CUS | ZPALLET/ZPALLET1/ZPAL_BOX/ZSOL_ASRS | unmanaged RAP → BAPI_HU_PACK |
| `backend/post-packing-gr-rap` | CUS | ZPOST01 | unmanaged RAP → BAPI_HU_PACK + BAPI_GOODSMVT_CREATE |
| `backend/hu-inbound-rap` | CUS | ZHUINB | unmanaged RAP → reuse `ZSOL_INBOUND_HU` |
| `backend/hu-phys-inventory-rap` | CUS | ZHUINV | unmanaged RAP → reuse `ZSOL_PHYS_INV_POST_SRV` |
| `backend/hu-unpack-rap` | CUS | ZHUPK | unmanaged RAP → BAPI_HU_UNPACK |
| `backend/batch-status-rap` | CUS | ZBATCHD, ZBATCH_CLS | unmanaged RAP → BAPI_BATCH_CHANGE / reuse `ZSOL_BATCH_CDS` |
| `backend/mto-mts-transfer-rap` | CUS | ZMTOS / ZHUINV (MTOS) | unmanaged RAP → BAPI_GOODSMVT_CREATE |
| `backend/goods-movement-hu-rap` | EXT | ZBOX_MOVE | unmanaged RAP → reuse `ZSOL_POST_GOODS_MOVEMENTS` |
| `backend/qm-mass-results-rap` | EXT | ZQA32 | read std QM + result API (legacy buffer `ZINSPLOT_QA32`) |
| `backend/contract-batch-rap` | EXT | ZBATCH_CHANGE | unmanaged RAP → reuse `ZSOL_SALE_ORDER_BATCH_UPDATE` |
| `backend/shade-master-rap` | EXT | ZDD_SHADE | managed RAP custom CBO (reference pattern) |
| `apps/manage-sales-contracts-ext` | EXT | ZCON_CLOSE/ZCOREL | adaptation of Manage Sales Contracts |
| `apps/manage-sales-orders-ext` | EXT | ZVA01/ZVA01N/ZSOCLOSE | adaptation of Manage Sales Orders (F1873) |
| `apps/manage-outbound-deliveries-ext` | CUS→EXT | ZDELC/ZDEL | Output Management on F0867A |

> Items in `EXT` like `ZCON_CLOSE`, `ZCOREL`, `ZSOCLOSE`, `ZVA01(N)` are sales-order/contract *close / release* add-ons — extend the standard Manage Sales Orders / Contracts apps (adaptation), reusing the existing `ZVBAP`-based logic rather than rebuilding the order UI.

