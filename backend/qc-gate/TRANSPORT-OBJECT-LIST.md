# Object list for the QC / Delivery Challan / Scan Suite transport

KSDK906908 was released at 19:38:05 on 5 Sep 2026 with the full 845-entry
list (six whole earlier requests merged in). A released request cannot be
edited, so the clean list below goes into a **new** workbench request.

59 entries, all R3TR. Everything is in package `ZKGPL_FIORI` except the
Scan Suite BSP application and its two ICF nodes, which are in `ZSOL_ISCAN`.

## Fastest way in: SE09 → Include Objects → *Object directory entry*

Request/Task → Object List → Include Objects → choose **Object directory
entry** (selection by TADIR). Two runs:

Run 1 — Package `ZKGPL_FIORI`, Object Type: exclude `STOB` and `SUSH`
(single-value exclusions), Object Name: multiple selection, one line each:

```
ZQC_*
ZI_QC_*
ZC_QC_*
ZD_QC_*
ZI_VH_QC_*
ZI_VH_PLANT
ZI_VH_COMPANYCODE
ZI_VH_CHALLAN_GRADE
ZI_VH_USER
ZI_QM_INSPECTIONCHAR
ZC_QM_INSPECTIONCHAR
ZBP_I_QM_INSPECTIONCHAR
ZBP_I_QC_INSP_LOT
ZUI_QC_INSPECTION*
ZUI_QM_INSPECTIONCHAR*
ZUI_DELIVERY_CHALLAN*
ZI_DELIVERY_CHALLAN
ZCL_DELIVERY_CHALLAN_QUERY
ZDLVCHALLAN*
ZREC_INSP_MASS*
```

Run 2 — Package `ZSOL_ISCAN`, Object Name `ZSOL_SCAN_SUITE*`.

Save. The result must be exactly the 59 rows below — 6 WAPA, 12 SICF,
24 DDLS, 4 BDEF, 3 CLAS, 3 SRVD, 3 SRVB, 3 G4BA, 1 TABL.

## The 59 entries (PgmID / Object / Object Name)

ICF object names are ICF node name padded to 15 characters + 25-char hash.
`4SYHDG1LJB52DAKB11MPN5S07` is the node under `/sap/bc/bsp/sap/`,
`907RM5PM0WS1BRG2HAYGJYC1N` the one under `/sap/bc/ui5_ui5/sap/`.

```
R3TR	WAPA	ZQC_RAW_DYE
R3TR	WAPA	ZQC_POST_DYE
R3TR	WAPA	ZQC_POST_WIND
R3TR	WAPA	ZREC_INSP_MASS
R3TR	WAPA	ZDLVCHALLAN
R3TR	WAPA	ZSOL_SCAN_SUITE
R3TR	SICF	ZQC_RAW_DYE    4SYHDG1LJB52DAKB11MPN5S07
R3TR	SICF	ZQC_RAW_DYE    907RM5PM0WS1BRG2HAYGJYC1N
R3TR	SICF	ZQC_POST_DYE   4SYHDG1LJB52DAKB11MPN5S07
R3TR	SICF	ZQC_POST_DYE   907RM5PM0WS1BRG2HAYGJYC1N
R3TR	SICF	ZQC_POST_WIND  4SYHDG1LJB52DAKB11MPN5S07
R3TR	SICF	ZQC_POST_WIND  907RM5PM0WS1BRG2HAYGJYC1N
R3TR	SICF	ZREC_INSP_MASS 4SYHDG1LJB52DAKB11MPN5S07
R3TR	SICF	ZREC_INSP_MASS 907RM5PM0WS1BRG2HAYGJYC1N
R3TR	SICF	ZDLVCHALLAN    4SYHDG1LJB52DAKB11MPN5S07
R3TR	SICF	ZDLVCHALLAN    907RM5PM0WS1BRG2HAYGJYC1N
R3TR	SICF	ZSOL_SCAN_SUITE4SYHDG1LJB52DAKB11MPN5S07
R3TR	SICF	ZSOL_SCAN_SUITE907RM5PM0WS1BRG2HAYGJYC1N
R3TR	DDLS	ZI_QC_INSP_LOT
R3TR	DDLS	ZC_QC_INSP_LOT
R3TR	DDLS	ZI_QC_INSP_CHAR
R3TR	DDLS	ZC_QC_INSP_CHAR
R3TR	DDLS	ZI_QC_BATCH_BY_GREIGE
R3TR	DDLS	ZI_QC_BATCH_BY_NO
R3TR	DDLS	ZI_QC_BATCH_JOB
R3TR	DDLS	ZI_QC_JOB_BY_BATCH
R3TR	DDLS	ZI_QC_LOT_ORDER
R3TR	DDLS	ZI_QC_ORDER_CONTEXT
R3TR	DDLS	ZD_QC_CONFIRM_PROD
R3TR	DDLS	ZD_QC_RECORD_RESULTS
R3TR	DDLS	ZD_QC_RELEASE_PROD
R3TR	DDLS	ZD_QC_SINGLE_RESULT
R3TR	DDLS	ZD_QC_USAGE_DECISION
R3TR	DDLS	ZI_VH_QC_BATCH
R3TR	DDLS	ZI_VH_QC_SUPPLIER_LOT
R3TR	DDLS	ZI_VH_PLANT
R3TR	DDLS	ZI_VH_COMPANYCODE
R3TR	DDLS	ZI_VH_CHALLAN_GRADE
R3TR	DDLS	ZI_VH_USER
R3TR	DDLS	ZI_QM_INSPECTIONCHAR
R3TR	DDLS	ZC_QM_INSPECTIONCHAR
R3TR	DDLS	ZI_DELIVERY_CHALLAN
R3TR	BDEF	ZI_QC_INSP_LOT
R3TR	BDEF	ZC_QC_INSP_LOT
R3TR	BDEF	ZI_QM_INSPECTIONCHAR
R3TR	BDEF	ZC_QM_INSPECTIONCHAR
R3TR	CLAS	ZBP_I_QC_INSP_LOT
R3TR	CLAS	ZBP_I_QM_INSPECTIONCHAR
R3TR	CLAS	ZCL_DELIVERY_CHALLAN_QUERY
R3TR	SRVD	ZUI_QC_INSPECTION
R3TR	SRVD	ZUI_QM_INSPECTIONCHAR
R3TR	SRVD	ZUI_DELIVERY_CHALLAN
R3TR	SRVB	ZUI_QC_INSPECTION_04
R3TR	SRVB	ZUI_QM_INSPECTIONCHAR_04
R3TR	SRVB	ZUI_DELIVERY_CHALLAN_04
R3TR	G4BA	ZUI_QC_INSPECTION_04
R3TR	G4BA	ZUI_QM_INSPECTIONCHAR_04
R3TR	G4BA	ZUI_DELIVERY_CHALLAN_04
R3TR	TABL	ZQC_CONF_BATCH
```

## Why these and nothing else

- Every CDS view the three service definitions expose, plus everything they
  read or name: `ZUI_QC_INSPECTION` exposes ZC_QC_INSP_LOT, ZC_QC_INSP_CHAR,
  ZI_QC_BATCH_JOB, ZI_VH_PLANT, ZI_VH_COMPANYCODE, ZI_VH_QC_BATCH,
  ZI_VH_QC_SUPPLIER_LOT; ZI_QC_INSP_LOT joins ZI_QC_LOT_ORDER,
  ZI_QC_ORDER_CONTEXT, ZI_QC_BATCH_JOB, which read ZI_QC_BATCH_BY_NO,
  ZI_QC_BATCH_BY_GREIGE, ZI_QC_JOB_BY_BATCH. ZI_DELIVERY_CHALLAN names
  ZI_VH_COMPANYCODE, ZI_VH_PLANT, ZI_VH_CHALLAN_GRADE, ZI_VH_USER in its
  value-help annotations - a missing one fails activation on import.
- The five ZD_QC_* abstract entities are the action parameters of the
  behaviour definition.
- Legacy tables and data elements the views and classes read - ZPP_BATCHN,
  ZPP_JOBN, ZPP_PACK, ZSOL_CHALLAN_LOG, ZDE_GCODE, ZDE_SIZE, ZDE_PLDATE,
  ZSPOOL, ZBOXNO, ZNETWT, ZDE_CHEESES - originate in TXT/KGD/KSD and exist in
  KSP already; they are not carried.
- Not carried on purpose from the 845-entry list: the five SAP Notes and
  their correction instructions, ENHO ZEINV_EDOC_TRIGGER / ZEWB_EDOC_TRIGGER,
  PROG ZEINV_EDOC_GEN, the CO11N module-pool includes, TABU /UI5/S_* and
  UI5V UI5001 (UI5 library registration), VDAT /UI2/V_SEMOBJC, the other 40
  BSP apps and 35 services of ZKGPL_FIORI, ZKGPL_ATO.

## After the include

1. Eclipse: paste the two class local-types files (ZBP_I_QC_INSP_LOT,
   ZBP_I_QM_INSPECTIONCHAR) and activate, recording on the new request.
2. Release the task(s), then the request. Import to KSQ, then KSP.
3. In the target, client 500: `/IWFND/V4_ADMIN` → Publish Service Groups →
   ZUI_QC_INSPECTION_04, ZUI_QM_INSPECTIONCHAR_04, ZUI_DELIVERY_CHALLAN_04.
4. Customizing request KSDK906757 (ZQC-UD selected set, plant 2002) is
   imported separately.
5. KSDK906908 stays in the KSQ import queue unimported; delete it from the
   queue in STMS so an "Import All" cannot pick it up.

## Deployment record — 5 Sep 2026

- KSDK906908 (845 entries) was released by mistake at 19:38 and must stay
  unimported; it sits in the KSQ import queue — delete it there.
- KSDK906915 (59 entries + task 906916 with the two class local includes)
  released and imported:
  - KSQ (hanaqas, 192.168.0.21:8003): first import RC 8 — `R3TR SICF
    ZREC_INSP_MASS 4SYH…` "was repaired in this system" (TW104). Cause: repair
    task KSQK900022 "Test Reactivation" held all 19 KSD-original ICF nodes
    from a service reactivation in KSQ. Fixed with SE03 → Unlock Objects
    (Expert Tool) → delete task/request → repair flags gone → re-import OK.
    Groups were already published in KSQ.
  - KSP (kejerpp4): no repaired ICF nodes; forwarded automatically after the
    KSQ import; imported into client 500; ICF nodes active; three V4 groups
    published.
- Verified through scan.kejriwalindustries.com (= KSP) from the Scan Suite
  session: zqc_raw_dye / zqc_post_dye / zqc_post_wind / zrec_insp_mass
  index.html 200; zsol_scan_suite index.html now 205,300 bytes (was 201,531);
  ZUI_QC_INSPECTION_04 service document lists 7 entity sets and
  InspectionLot?$count = 3,121,358; ZUI_QM_INSPECTIONCHAR_04
  InspectionCharacteristic?$count = 2,155,087; ZUI_DELIVERY_CHALLAN_04
  answers 200 (empty without filter).
- Still open: nginx returns 403 for /sap/bc/ui5_ui5/sap/zdlvchallan/ (only
  the V4 service is allow-listed); customizing KSDK906757 (ZQC-UD selected
  set, plant 2002) to be imported into KSP; end-to-end test of one lot.
