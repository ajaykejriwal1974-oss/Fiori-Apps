CLASS lhc_labelmaster DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR LabelMaster RESULT result.
    METHODS enforcesingledefault FOR DETERMINE ON SAVE
      IMPORTING keys FOR LabelMaster~enforceSingleDefault.
ENDCLASS.

CLASS lhc_labelmaster IMPLEMENTATION.

  METHOD get_global_authorizations.
    " Unchanged. No dedicated Z authorization object exists for the label master;
    " replace with an AUTHORITY-CHECK once one does.
    result-%create = if_abap_behv=>auth-allowed.
    result-%update = if_abap_behv=>auth-allowed.
    result-%delete = if_abap_behv=>auth-allowed.
  ENDMETHOD.

  " One default per plant + label type.
  "
  " ZPP_LABEL is keyed on plant, type and IP, and nothing ever stopped a second
  " row in the same plant and type being flagged default. Plant 2002 now has
  " nine defaults for KIL and three for BLNK, so the printer a KIL label goes to
  " depends on which row the SELECT returns first.
  "
  " Runs on save, after the row is in the buffer but before it is written, so
  " the MODIFY below lands in the same LUW.
  METHOD enforcesingledefault.

    READ ENTITIES OF zi_label_master IN LOCAL MODE
      ENTITY LabelMaster FIELDS ( Plant LabelType IPAddress IsDefault )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_saved).

    DATA lt_clear TYPE TABLE FOR UPDATE zi_label_master.

    LOOP AT lt_saved INTO DATA(ls_saved) WHERE IsDefault = 'X'.

      " Every other printer in the same plant and type loses the flag. The row
      " being saved is excluded by its own IP, so a re-save of the current
      " default is a no-op rather than a flap.
      SELECT werks, type, ip FROM zpp_label
        WHERE werks =  @ls_saved-Plant
          AND type  =  @ls_saved-LabelType
          AND ip    <> @ls_saved-IPAddress
          AND dflt  =  'X'
        INTO TABLE @DATA(lt_others).

      LOOP AT lt_others INTO DATA(ls_other).
        APPEND VALUE #( %key-Plant     = ls_other-werks
                        %key-LabelType = ls_other-type
                        %key-IPAddress = ls_other-ip
                        IsDefault      = space
                        %control-IsDefault = if_abap_behv=>mk-on ) TO lt_clear.
      ENDLOOP.

    ENDLOOP.

    IF lt_clear IS NOT INITIAL.
      MODIFY ENTITIES OF zi_label_master IN LOCAL MODE
        ENTITY LabelMaster UPDATE FIELDS ( IsDefault )
        WITH lt_clear
        REPORTED DATA(lt_rep).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
