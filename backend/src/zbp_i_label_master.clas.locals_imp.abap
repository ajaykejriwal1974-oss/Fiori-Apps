CLASS lhc_labelmaster DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR LabelMaster
      RESULT result.
ENDCLASS.

CLASS lhc_labelmaster IMPLEMENTATION.
  METHOD get_global_authorizations.
    " No dedicated Z authorization object exists for the print label master
    " yet, so access is governed by the ZUI_LABEL_MASTER_04 service-group
    " entry in the PFCG role. Replace these with AUTHORITY-CHECK once a
    " proper auth object is created.
    result-%create = if_abap_behv=>auth-allowed.
    result-%update = if_abap_behv=>auth-allowed.
    result-%delete = if_abap_behv=>auth-allowed.
  ENDMETHOD.
ENDCLASS.
