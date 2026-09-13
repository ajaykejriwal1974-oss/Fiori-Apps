class ZCL_ZSOL_KNIT_QC_MPC definition
  public
  inheriting from /IWBEP/CL_MGW_PUSH_ABS_MODEL
  create public .

public section.

* ----------------------------------------------------------------------
* Scan Suite - Knitting Roll QC (Mango Filament, company code 8000).
*
* Hand-written model, same shape as ZCL_ZSOL_SCAN_READ_MPC: no SEGW
* project, so the class is the model and can be edited directly. The
* rules live in ZCL_ZKNIT_ROLL_QC; this class only names the fields.
*
* One entity type, Roll, serves four sets - the roll as scanned
* (RollSet), the packing hold list (HoldSet), the lab's worklist
* (PendingDyeSet) and the production list (ProductionSet) - so the
* handheld renders every list with one piece of code. Two small lookup
* sets carry the defect codes and the knitting grades.
*
* Every date is YYYYMMDD in an Edm.String, every time HHMMSS, as in the
* other suite services. RollSet is also the write: POST with Action set
* to PQC (Physical QC), DRECV (sample received by the lab) or DRES
* (result; DqcStatus C or F). The response is the roll as it now stands
* plus Message.
* ----------------------------------------------------------------------

  types:
    begin of TS_ROLL,
      WERKS         type c length 4,
      ARBPL         type c length 8,
      MRNO          type c length 6,
      ZMRNO         type c length 15,
      AUFNR         type c length 12,
      MATNR         type c length 40,
      MAKTX         type c length 40,
      PRINT_DATE    type c length 8,
      PQC_DATE      type c length 8,
      PQC_TIME      type c length 6,
      PQC_USER      type c length 40,
      PQC_GRADE     type c length 1,
      PQC_GRADE_TXT type c length 20,
      PQC_DEFECTS   type c length 60,
      PQC_REMARK    type c length 100,
      DQC_STATUS    type c length 1,
      DQC_SENT_DATE type c length 8,
      DQC_RECV_DATE type c length 8,
      DQC_RES_DATE  type c length 8,
      DQC_RES_USER  type c length 40,
      DQC_REMARK    type c length 100,
      DAYS_PENDING  type i,
      HOLD          type c length 1,
      PACK_BOXNO    type c length 10,
      PACK_GRADE    type c length 1,
      PACK_DATE     type c length 8,
      PACK_NETWT    type c length 17,
      EXISTS        type c length 1,
      ACTION        type c length 10,
      DYE_SAMPLE    type c length 1,
      MESSAGE       type c length 220,
    end of TS_ROLL .
  types:
    TT_ROLL type standard table of TS_ROLL with default key .

  types:
    begin of TS_DEFECT,
      WERKS  type c length 4,
      DCODE  type c length 4,
      DESCR  type c length 40,
      SORTNO type c length 3,
    end of TS_DEFECT .
  types:
    TT_DEFECT type standard table of TS_DEFECT with default key .

  types:
    begin of TS_GRADE,
      GCODE type c length 1,
      GDESC type c length 20,
    end of TS_GRADE .
  types:
    TT_GRADE type standard table of TS_GRADE with default key .

  constants GC_SET_ROLL    type string value 'RollSet' ##NO_TEXT.
  constants GC_SET_HOLD    type string value 'HoldSet' ##NO_TEXT.
  constants GC_SET_PENDING type string value 'PendingDyeSet' ##NO_TEXT.
  constants GC_SET_PROD    type string value 'ProductionSet' ##NO_TEXT.
  constants GC_SET_DEFECT  type string value 'DefectCodeSet' ##NO_TEXT.
  constants GC_SET_GRADE   type string value 'GradeSet' ##NO_TEXT.

  methods DEFINE
    redefinition .
  methods GET_LAST_MODIFIED
    redefinition .

protected section.
private section.

  methods ADD_STRING
    importing
      !IO_TYPE   type ref to /IWBEP/IF_MGW_ODATA_ENTITY_TYP
      !IV_NAME   type STRING
      !IV_FIELD  type STRING
      !IV_LENGTH type I
      !IV_KEY    type ABAP_BOOL default ABAP_FALSE
    raising
      /IWBEP/CX_MGW_MED_EXCEPTION .
  methods ADD_SET
    importing
      !IO_TYPE     type ref to /IWBEP/IF_MGW_ODATA_ENTITY_TYP
      !IV_SET_NAME type STRING
    raising
      /IWBEP/CX_MGW_MED_EXCEPTION .

ENDCLASS.



CLASS ZCL_ZSOL_KNIT_QC_MPC IMPLEMENTATION.


  METHOD add_string.
    DATA(lo_property) = io_type->create_property( iv_property_name  = CONV #( iv_name )
                                                  iv_abap_fieldname = CONV #( iv_field ) ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = iv_length ).
    IF iv_key = abap_true.
      lo_property->set_is_key( ).
      lo_property->set_nullable( abap_false ).
    ELSE.
      lo_property->set_nullable( abap_true ).
    ENDIF.
    lo_property->set_creatable( abap_true ).
    lo_property->set_updatable( abap_false ).
    lo_property->set_sortable( abap_false ).
    lo_property->set_filterable( abap_true ).
  ENDMETHOD.


  METHOD add_set.
    DATA(lo_set) = io_type->create_entity_set( CONV #( iv_set_name ) ).
    lo_set->set_creatable( xsdbool( iv_set_name = gc_set_roll ) ).
    lo_set->set_updatable( abap_false ).
    lo_set->set_deletable( abap_false ).
    lo_set->set_pageable( abap_true ).
    lo_set->set_addressable( abap_true ).
    lo_set->set_has_ftxt_search( abap_false ).
    lo_set->set_subscribable( abap_false ).
    lo_set->set_filter_required( abap_false ).
  ENDMETHOD.


  METHOD define.

    DATA: lo_type TYPE REF TO /iwbep/if_mgw_odata_entity_typ,
          lo_prop TYPE REF TO /iwbep/if_mgw_odata_property.

    model->set_schema_namespace( 'ZSOL_KNIT_QC_SRV' ).

*   ---- Roll: one type, four sets ------------------------------------
    lo_type = model->create_entity_type( iv_entity_type_name = 'Roll'
                                         iv_def_entity_set   = abap_false ).
    add_string( io_type = lo_type iv_name = 'Werks'       iv_field = 'WERKS'         iv_length = 4  iv_key = abap_true ).
    add_string( io_type = lo_type iv_name = 'Arbpl'       iv_field = 'ARBPL'         iv_length = 8  iv_key = abap_true ).
    add_string( io_type = lo_type iv_name = 'Mrno'        iv_field = 'MRNO'          iv_length = 6  iv_key = abap_true ).
    add_string( io_type = lo_type iv_name = 'Zmrno'       iv_field = 'ZMRNO'         iv_length = 15 ).
    add_string( io_type = lo_type iv_name = 'Aufnr'       iv_field = 'AUFNR'         iv_length = 12 ).
    add_string( io_type = lo_type iv_name = 'Matnr'       iv_field = 'MATNR'         iv_length = 40 ).
    add_string( io_type = lo_type iv_name = 'Maktx'       iv_field = 'MAKTX'         iv_length = 40 ).
    add_string( io_type = lo_type iv_name = 'PrintDate'   iv_field = 'PRINT_DATE'    iv_length = 8 ).
    add_string( io_type = lo_type iv_name = 'PqcDate'     iv_field = 'PQC_DATE'      iv_length = 8 ).
    add_string( io_type = lo_type iv_name = 'PqcTime'     iv_field = 'PQC_TIME'      iv_length = 6 ).
    add_string( io_type = lo_type iv_name = 'PqcUser'     iv_field = 'PQC_USER'      iv_length = 40 ).
    add_string( io_type = lo_type iv_name = 'PqcGrade'    iv_field = 'PQC_GRADE'     iv_length = 1 ).
    add_string( io_type = lo_type iv_name = 'PqcGradeTxt' iv_field = 'PQC_GRADE_TXT' iv_length = 20 ).
    add_string( io_type = lo_type iv_name = 'PqcDefects'  iv_field = 'PQC_DEFECTS'   iv_length = 60 ).
    add_string( io_type = lo_type iv_name = 'PqcRemark'   iv_field = 'PQC_REMARK'    iv_length = 100 ).
    add_string( io_type = lo_type iv_name = 'DqcStatus'   iv_field = 'DQC_STATUS'    iv_length = 1 ).
    add_string( io_type = lo_type iv_name = 'DqcSentDate' iv_field = 'DQC_SENT_DATE' iv_length = 8 ).
    add_string( io_type = lo_type iv_name = 'DqcRecvDate' iv_field = 'DQC_RECV_DATE' iv_length = 8 ).
    add_string( io_type = lo_type iv_name = 'DqcResDate'  iv_field = 'DQC_RES_DATE'  iv_length = 8 ).
    add_string( io_type = lo_type iv_name = 'DqcResUser'  iv_field = 'DQC_RES_USER'  iv_length = 40 ).
    add_string( io_type = lo_type iv_name = 'DqcRemark'   iv_field = 'DQC_REMARK'    iv_length = 100 ).
    lo_prop = lo_type->create_property( iv_property_name = 'DaysPending' iv_abap_fieldname = 'DAYS_PENDING' ).
    lo_prop->set_type_edm_int32( ).
    lo_prop->set_creatable( abap_false ).
    lo_prop->set_updatable( abap_false ).
    lo_prop->set_sortable( abap_false ).
    lo_prop->set_filterable( abap_false ).
    add_string( io_type = lo_type iv_name = 'Hold'        iv_field = 'HOLD'          iv_length = 1 ).
    add_string( io_type = lo_type iv_name = 'PackBoxno'   iv_field = 'PACK_BOXNO'    iv_length = 10 ).
    add_string( io_type = lo_type iv_name = 'PackGrade'   iv_field = 'PACK_GRADE'    iv_length = 1 ).
    add_string( io_type = lo_type iv_name = 'PackDate'    iv_field = 'PACK_DATE'     iv_length = 8 ).
    add_string( io_type = lo_type iv_name = 'PackNetwt'   iv_field = 'PACK_NETWT'    iv_length = 17 ).
    add_string( io_type = lo_type iv_name = 'Exists'      iv_field = 'EXISTS'        iv_length = 1 ).
    add_string( io_type = lo_type iv_name = 'Action'      iv_field = 'ACTION'        iv_length = 10 ).
    add_string( io_type = lo_type iv_name = 'DyeSample'   iv_field = 'DYE_SAMPLE'    iv_length = 1 ).
    add_string( io_type = lo_type iv_name = 'Message'     iv_field = 'MESSAGE'       iv_length = 220 ).
    lo_type->bind_structure( iv_structure_name = 'ZCL_ZSOL_KNIT_QC_MPC=>TS_ROLL' ).

    add_set( io_type = lo_type iv_set_name = gc_set_roll ).
    add_set( io_type = lo_type iv_set_name = gc_set_hold ).
    add_set( io_type = lo_type iv_set_name = gc_set_pending ).
    add_set( io_type = lo_type iv_set_name = gc_set_prod ).

*   ---- Defect codes --------------------------------------------------
    lo_type = model->create_entity_type( iv_entity_type_name = 'DefectCode'
                                         iv_def_entity_set   = abap_false ).
    add_string( io_type = lo_type iv_name = 'Werks'  iv_field = 'WERKS'  iv_length = 4  iv_key = abap_true ).
    add_string( io_type = lo_type iv_name = 'Dcode'  iv_field = 'DCODE'  iv_length = 4  iv_key = abap_true ).
    add_string( io_type = lo_type iv_name = 'Descr'  iv_field = 'DESCR'  iv_length = 40 ).
    add_string( io_type = lo_type iv_name = 'Sortno' iv_field = 'SORTNO' iv_length = 3 ).
    lo_type->bind_structure( iv_structure_name = 'ZCL_ZSOL_KNIT_QC_MPC=>TS_DEFECT' ).
    add_set( io_type = lo_type iv_set_name = gc_set_defect ).

*   ---- Knitting grades (ZPP_GRADE, order type KNT) -------------------
    lo_type = model->create_entity_type( iv_entity_type_name = 'Grade'
                                         iv_def_entity_set   = abap_false ).
    add_string( io_type = lo_type iv_name = 'Gcode' iv_field = 'GCODE' iv_length = 1  iv_key = abap_true ).
    add_string( io_type = lo_type iv_name = 'Gdesc' iv_field = 'GDESC' iv_length = 20 ).
    lo_type->bind_structure( iv_structure_name = 'ZCL_ZSOL_KNIT_QC_MPC=>TS_GRADE' ).
    add_set( io_type = lo_type iv_set_name = gc_set_grade ).

  ENDMETHOD.


  METHOD get_last_modified.
    CONSTANTS lc_gen_date_time TYPE timestamp VALUE '20260906150000'.
    rv_last_modified = super->get_last_modified( ).
    IF rv_last_modified LT lc_gen_date_time.
      rv_last_modified = lc_gen_date_time.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
