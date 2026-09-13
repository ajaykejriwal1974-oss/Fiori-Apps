class ZCL_ZSOL_SCAN_READ_01_MPC_EXT definition
  public
  inheriting from ZCL_ZSOL_SCAN_READ_01_MPC
  create public .

public section.

* ----------------------------------------------------------------------
* DEFINE is redefined (10.09.2026) to repair the ZSOL_SO_BOXCHECK
* entity. The generated base class declares only the two key properties
* (vbeln, posnr), so Gateway serialised every other field away: the
* handheld's "Why no boxes?" card rendered blank rows and the SOCHG
* assign-batch flow - which knitting roll orders (plants 8001/8003)
* depend on for any boxes at all - had no lots to offer. The front end
* was pinned back to the OLD service the same day as a stopgap.
*
* The base class's DEFINE_SOBOXCHECK is PRIVATE, so it cannot be
* redefined; instead this DEFINE lets the base build the model, then
* fetches the SoBoxCheck entity back and adds the missing properties -
* the OLD model's def_so_check (ZCL_ZSOL_SCAN_READ_MPC) property for
* property - and re-binds the structure the DPC_EXT actually fills,
* ZCL_ZSOL_SCAN_READ_MPC=>TS_SO_CHECK, so the two services cannot
* drift apart while both exist. No SEGW project generates these
* classes (/IWBEP/I_SBD_PR holds no ZSOL_SCAN_READ_01 - the model is
* registered directly on this class), so nothing regenerates over this.
*
* Once this is verified in production the front end flips WHY_SERVICE
* back to the _01 service and the old service can finally retire (the
* scheduled cleanup task carries the conditions).
* ----------------------------------------------------------------------
  methods DEFINE
    redefinition .
protected section.
private section.
ENDCLASS.



CLASS ZCL_ZSOL_SCAN_READ_01_MPC_EXT IMPLEMENTATION.


  METHOD define.

    TYPES: BEGIN OF ty_def,
             name  TYPE string,
             field TYPE string,
             len   TYPE i,
           END OF ty_def.

    DATA lo_entity_type TYPE REF TO /iwbep/if_mgw_odata_entity_typ.
    DATA lo_property    TYPE REF TO /iwbep/if_mgw_odata_property.
    DATA lt_def         TYPE STANDARD TABLE OF ty_def WITH EMPTY KEY.
    DATA lt_int         TYPE STANDARD TABLE OF ty_def WITH EMPTY KEY.

    super->define( ).

    " The entity the base just created, with only its two keys.
    lo_entity_type = model->get_entity_type( iv_entity_name = 'SoBoxCheck' ).
    IF lo_entity_type IS NOT BOUND.
      RETURN.
    ENDIF.

    " The 25 string properties of the old model, same names, same
    " lengths. EDM names are lower case because that is what the
    " handheld reads (r.werks, r.need_batch, ...).
    lt_def = VALUE #( ( name = 'matnr'       field = 'MATNR'       len = 40 )
                      ( name = 'arktx'       field = 'ARKTX'       len = 40 )
                      ( name = 'werks'       field = 'WERKS'       len = 4 )
                      ( name = 'lgort'       field = 'LGORT'       len = 4 )
                      ( name = 'charg'       field = 'CHARG'       len = 10 )
                      ( name = 'kwmeng'      field = 'KWMENG'      len = 17 )
                      ( name = 'vrkme'       field = 'VRKME'       len = 3 )
                      ( name = 'dis_qty'     field = 'DIS_QTY'     len = 17 )
                      ( name = 'open_qty'    field = 'OPEN_QTY'    len = 17 )
                      ( name = 'abgru'       field = 'ABGRU'       len = 2 )
                      ( name = 'zzsize'      field = 'ZZSIZE'      len = 4 )
                      ( name = 'zzsiz1'      field = 'ZZSIZ1'      len = 4 )
                      ( name = 'zzsiz2'      field = 'ZZSIZ2'      len = 4 )
                      ( name = 'zzgrade'     field = 'ZZGRADE'     len = 1 )
                      ( name = 'zzgrad1'     field = 'ZZGRAD1'     len = 1 )
                      ( name = 'zzgrad2'     field = 'ZZGRAD2'     len = 1 )
                      ( name = 'so_batches'  field = 'SO_BATCHES'  len = 120 )
                      ( name = 'batch_src'   field = 'BATCH_SRC'   len = 1 )
                      ( name = 'match_wt'    field = 'MATCH_WT'    len = 17 )
                      ( name = 'need_batch'  field = 'NEED_BATCH'  len = 220 )
                      ( name = 'other_lgort' field = 'OTHER_LGORT' len = 120 )
                      ( name = 'other_size'  field = 'OTHER_SIZE'  len = 120 )
                      ( name = 'other_grade' field = 'OTHER_GRADE' len = 120 )
                      ( name = 'other_so'    field = 'OTHER_SO'    len = 120 )
                      ( name = 'hint'        field = 'HINT'        len = 220 ) ).

    LOOP AT lt_def INTO DATA(ls_def).
      lo_property = lo_entity_type->create_property(
        iv_property_name  = CONV #( ls_def-name )
        iv_abap_fieldname = CONV #( ls_def-field ) ).
      lo_property->set_type_edm_string( ).
      lo_property->set_maxlength( iv_max_length = ls_def-len ).
      lo_property->set_creatable( abap_false ).
      lo_property->set_updatable( abap_false ).
    ENDLOOP.

    " And the four counters.
    lt_int = VALUE #( ( name = 'cand_cnt'   field = 'CAND_CNT' )
                      ( name = 'match_cnt'  field = 'MATCH_CNT' )
                      ( name = 'on_deliv'   field = 'ON_DELIV' )
                      ( name = 'not_posted' field = 'NOT_POSTED' ) ).

    LOOP AT lt_int INTO ls_def.
      lo_property = lo_entity_type->create_property(
        iv_property_name  = CONV #( ls_def-name )
        iv_abap_fieldname = CONV #( ls_def-field ) ).
      lo_property->set_type_edm_int32( ).
      lo_property->set_creatable( abap_false ).
      lo_property->set_updatable( abap_false ).
      lo_property->set_filterable( abap_false ).
    ENDLOOP.

    " Re-bind from the base's two-field TS_SOBOXCHECK to the structure
    " the DPC_EXT actually returns rows in.
    lo_entity_type->bind_structure(
      iv_structure_name = 'ZCL_ZSOL_SCAN_READ_MPC=>TS_SO_CHECK' ).

  ENDMETHOD.
ENDCLASS.
