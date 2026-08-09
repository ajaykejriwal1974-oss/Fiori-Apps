*&---------------------------------------------------------------------*
*& Report ZSO_RELEASE
*& Frontend for ZCL_SO_RELEASE: release sales orders (set order reason)
*& via BAPI_SALESORDER_CHANGE. Clean-core successor UI for ZV2.
*&---------------------------------------------------------------------*
REPORT zso_release.

DATA gv_vbeln TYPE vbeln_va.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME.
  SELECT-OPTIONS s_vbeln FOR gv_vbeln OBLIGATORY.
  PARAMETERS: p_augru TYPE augru DEFAULT '001',
              p_test  AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b1.

START-OF-SELECTION.

  DATA(lt_log) = NEW zcl_so_release( )->release(
    it_vbeln  = s_vbeln[]
    iv_reason = p_augru
    iv_test   = p_test ).

  IF p_test = abap_true.
    WRITE: / 'Simulation - untick "P_TEST" to post:' COLOR COL_TOTAL.
    SKIP.
  ENDIF.

  LOOP AT lt_log INTO DATA(lv_line).
    WRITE / lv_line.
  ENDLOOP.
  IF lt_log IS INITIAL.
    WRITE / 'No sales orders processed.'.
  ENDIF.
