*&---------------------------------------------------------------------*
*& Report ZSOL_KNIT_QC_SEED
*&---------------------------------------------------------------------*
*& One-off: fills ZKNIT_QC_DEFECT with the standard knitted-fabric
*& defect codes when the table is still empty (blank plant = every
*& knitting plant). Run once per system after the table exists; rows
*& that already exist are left alone, so re-running is harmless.
*& Edit the list below or maintain the table in SE16N / SM30 afterwards.
*&---------------------------------------------------------------------*
REPORT zsol_knit_qc_seed.

PARAMETERS p_test TYPE abap_bool AS CHECKBOX DEFAULT abap_true.

TYPES: BEGIN OF ty_seed,
         dcode  TYPE c LENGTH 4,
         descr  TYPE c LENGTH 40,
         sortno TYPE n LENGTH 3,
       END OF ty_seed.

DATA lt_seed TYPE STANDARD TABLE OF ty_seed WITH EMPTY KEY.
DATA ls_row  TYPE zknit_qc_defect.
DATA lv_new  TYPE i.
DATA lv_old  TYPE i.

lt_seed = VALUE #(
  ( dcode = 'HOLE' descr = 'Hole / cut'                       sortno = '010' )
  ( dcode = 'NDLN' descr = 'Needle line'                      sortno = '020' )
  ( dcode = 'DRST' descr = 'Drop stitch / missing loop'       sortno = '030' )
  ( dcode = 'BARR' descr = 'Barre / horizontal stripes'       sortno = '040' )
  ( dcode = 'THTN' descr = 'Thick-thin yarn'                  sortno = '050' )
  ( dcode = 'OILS' descr = 'Oil / grease stain'               sortno = '060' )
  ( dcode = 'CONT' descr = 'Contamination / fly / foreign fibre' sortno = '070' )
  ( dcode = 'LYCR' descr = 'Lycra missing / broken'           sortno = '080' )
  ( dcode = 'SNAG' descr = 'Snag / pulled loop'               sortno = '090' )
  ( dcode = 'PRSO' descr = 'Press-off'                        sortno = '100' )
  ( dcode = 'GSMV' descr = 'GSM / width variation'            sortno = '110' )
  ( dcode = 'CREA' descr = 'Crease / fold mark'               sortno = '120' )
  ( dcode = 'DYEU' descr = 'Dye pick-up unevenness (sample)'  sortno = '130' )
  ( dcode = 'OTHR' descr = 'Other - see remark'               sortno = '990' ) ).

LOOP AT lt_seed INTO DATA(ls_seed).
  SELECT SINGLE dcode FROM zknit_qc_defect
    WHERE werks = @space AND dcode = @ls_seed-dcode
    INTO @DATA(lv_exists).
  IF sy-subrc = 0.
    lv_old = lv_old + 1.
    WRITE: / 'exists ', ls_seed-dcode, ls_seed-descr.
    CONTINUE.
  ENDIF.
  CLEAR ls_row.
  ls_row-mandt  = sy-mandt.
  ls_row-werks  = space.
  ls_row-dcode  = ls_seed-dcode.
  ls_row-descr  = ls_seed-descr.
  ls_row-sortno = ls_seed-sortno.
  IF p_test = abap_false.
    INSERT zknit_qc_defect FROM @ls_row.
  ENDIF.
  lv_new = lv_new + 1.
  WRITE: / 'new    ', ls_seed-dcode, ls_seed-descr.
ENDLOOP.

IF p_test = abap_false.
  COMMIT WORK.
  WRITE: / |{ lv_new } defect codes inserted, { lv_old } already present.|.
ELSE.
  WRITE: / |Test run: { lv_new } would be inserted, { lv_old } already present. Untick "Test" to write.|.
ENDIF.
