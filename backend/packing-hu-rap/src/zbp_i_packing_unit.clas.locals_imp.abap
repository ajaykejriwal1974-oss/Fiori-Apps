*"* Unmanaged behavior for ZI_Packing_Unit.
*"* createHandlingUnits: build the cone -> carton -> pallet HU hierarchy for the
*"* reference and pack it via the standard HU API.

CLASS lhc_PackingUnit DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS createHandlingUnits FOR MODIFY
      IMPORTING keys FOR ACTION PackingUnit~createHandlingUnits RESULT result.
ENDCLASS.

CLASS lhc_PackingUnit IMPLEMENTATION.

  METHOD createHandlingUnits.
    LOOP AT keys INTO DATA(key).
      DATA(ls_header) = key-%param.
      DATA(lt_units)  = key-%param-_unit.

      IF lt_units IS INITIAL.
        APPEND VALUE #( %cid = key-%cid
                        %param-message = 'No packing units provided' ) TO result.
        CONTINUE.
      ENDIF.

      " TODO: create + pack the HU hierarchy via the standard HU API.
      "   For each level (Cone -> Carton -> Pallet), create the HU
      "   (BAPI_HU_CREATE with packaging material = unit-packingmaterial) and
      "   pack the lower level / contents into it (BAPI_HU_PACK), carrying
      "   net/gross weights. Link to ls_header-reference (delivery/order).
      "   Collect messages into reported/failed; commit on success.

      APPEND VALUE #( %cid  = key-%cid
                      %param = VALUE #( handlingunitscreated = lines( lt_units )
                                        tophandlingunit      = ''
                                        message              = 'TODO: wire BAPI_HU_CREATE / BAPI_HU_PACK' ) )
             TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
