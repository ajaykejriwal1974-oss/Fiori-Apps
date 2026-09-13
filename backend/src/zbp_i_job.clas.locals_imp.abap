" Pre-image of the batch number, captured before the managed save writes the new
" one. ZJOB01N keeps the same thing in v_oldbatch so it can release the batch a
" job card is moving away from.
CLASS lcl_job_buffer DEFINITION.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_old,
             jobno   TYPE zpp_jobn-jobno,
             batchno TYPE zpp_jobn-batchno,
           END OF ty_old.
    CLASS-DATA gt_old TYPE SORTED TABLE OF ty_old WITH UNIQUE KEY jobno.
ENDCLASS.

CLASS lhc_job DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS setadmindata FOR DETERMINE ON SAVE
      IMPORTING keys FOR Job~setAdminData.
    METHODS stasholdbatch FOR DETERMINE ON SAVE
      IMPORTING keys FOR Job~stashOldBatch.
    METHODS markdeleted FOR MODIFY
      IMPORTING keys FOR ACTION Job~markDeleted RESULT result.
    " The ZJOB01N create rules, enforced on save. See the validation's comment
    " in ZI_JOB for what each check corresponds to in MZ_PP_JOB_CARDNF01.
    METHODS validatejobcard FOR VALIDATE ON SAVE
      IMPORTING keys FOR Job~validateJobCard.
ENDCLASS.

CLASS lhc_job IMPLEMENTATION.

  METHOD setadmindata.
    " Idempotent, and it MUST be: this is an on-save determination that
    " triggers on update and itself performs an update, so RAP re-runs it
    " after its own write. If the second run also writes, the determination
    " never converges and the framework aborts the save with
    " LCX_ABAP_BEHV_DETVAL_ERROR ("cyclical triggering of on-save
    " determinations"). So we read the current admin fields and queue an
    " update only for values that actually change - on the re-run nothing is
    " left to change, no MODIFY happens, and the save converges.
    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).
    GET TIME.
    DATA(lv_now) = sy-uzeit.
    READ ENTITIES OF zi_job IN LOCAL MODE
      ENTITY Job FIELDS ( CreatedOnDate CreatedAtTime LastChangedDate LastChangedTime )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt).
    DATA lt_upd TYPE TABLE FOR UPDATE zi_job.
    DATA ls_upd TYPE STRUCTURE FOR UPDATE zi_job.
    LOOP AT lt INTO DATA(ls).
      CLEAR ls_upd.
      ls_upd-%tky = ls-%tky.
      DATA(lv_change) = abap_false.
      IF ls-CreatedOnDate IS INITIAL.
        ls_upd-CreatedOnDate = lv_today.
        ls_upd-CreatedAtTime = lv_now.
        ls_upd-%control-CreatedOnDate = if_abap_behv=>mk-on.
        ls_upd-%control-CreatedAtTime = if_abap_behv=>mk-on.
        lv_change = abap_true.
      ENDIF.
      IF ls-LastChangedDate <> lv_today OR ls-LastChangedTime <> lv_now.
        ls_upd-LastChangedDate = lv_today.
        ls_upd-LastChangedTime = lv_now.
        ls_upd-%control-LastChangedDate = if_abap_behv=>mk-on.
        ls_upd-%control-LastChangedTime = if_abap_behv=>mk-on.
        lv_change = abap_true.
      ENDIF.
      IF lv_change = abap_true.
        APPEND ls_upd TO lt_upd.
      ENDIF.
    ENDLOOP.
    IF lt_upd IS NOT INITIAL.
      MODIFY ENTITIES OF zi_job IN LOCAL MODE
        ENTITY Job UPDATE FROM lt_upd
        REPORTED DATA(lt_rep).
    ENDIF.
  ENDMETHOD.

  " Determinations on save run before the row is persisted, so this SELECT still
  " sees the batch the job card had when it was opened. save_modified reads it
  " back to release that batch if the card has moved.
  METHOD stasholdbatch.
    LOOP AT keys INTO DATA(ls_key).
      SELECT SINGLE jobno, batchno FROM zpp_jobn
        WHERE jobno = @ls_key-JobNumber
        INTO @DATA(ls_db).
      IF sy-subrc = 0.
        INSERT VALUE #( jobno = ls_db-jobno batchno = ls_db-batchno )
          INTO TABLE lcl_job_buffer=>gt_old.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  " The create-time rules of ZJOB01N (MZ_PP_JOB_CARDNF01), which the Fiori path
  " never enforced. On CREATE only: JobNumber is the key and must equal
  " BatchNumber, so a card's batch never changes on update and the "batch is
  " free" tests below would otherwise reject a card editing its own row. Each
  " failing instance is marked failed and given a message on the offending
  " field, so Fiori elements shows it against the right input.
  METHOD validatejobcard.

    READ ENTITIES OF zi_job IN LOCAL MODE
      ENTITY Job ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_job).

    LOOP AT lt_job INTO DATA(ls).

      " A row created and marked deleted in the same save needs no checking.
      IF ls-DeletionFlag = 'X'.
        CONTINUE.
      ENDIF.

      " 1. Job number must equal the batch number (true for every one of the
      "    131,340 job cards in KSD; ZPP_JOBN keys on JOBNO alone).
      IF ls-JobNumber <> ls-BatchNumber.
        APPEND VALUE #( %tky = ls-%tky ) TO failed-job.
        APPEND VALUE #( %tky = ls-%tky
                        %element-JobNumber   = if_abap_behv=>mk-on
                        %element-BatchNumber = if_abap_behv=>mk-on
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = |Job card number must equal the batch number.| ) )
          TO reported-job.
        CONTINUE.
      ENDIF.

      " 2. The batch must exist and be live and free. GJAHR '0000' rows are the
      "    2019 migration duplicates - skip them.
      SELECT SINGLE werks, dye_code, delind, closed, assigned
        FROM zpp_batchn
        WHERE batchno = @ls-BatchNumber AND gjahr <> '0000'
        INTO @DATA(ls_bat).
      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = ls-%tky ) TO failed-job.
        APPEND VALUE #( %tky = ls-%tky %element-BatchNumber = if_abap_behv=>mk-on
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = |Batch { ls-BatchNumber } does not exist.| ) )
          TO reported-job.
        CONTINUE.
      ENDIF.
      IF ls_bat-delind = 'X'.
        APPEND VALUE #( %tky = ls-%tky ) TO failed-job.
        APPEND VALUE #( %tky = ls-%tky %element-BatchNumber = if_abap_behv=>mk-on
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = |Batch { ls-BatchNumber } is deleted.| ) )
          TO reported-job.
        CONTINUE.
      ENDIF.
      IF ls_bat-closed = 'X'.
        APPEND VALUE #( %tky = ls-%tky ) TO failed-job.
        APPEND VALUE #( %tky = ls-%tky %element-BatchNumber = if_abap_behv=>mk-on
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = |Batch { ls-BatchNumber } is closed.| ) )
          TO reported-job.
        CONTINUE.
      ENDIF.
      IF ls_bat-assigned = 'X'.
        APPEND VALUE #( %tky = ls-%tky ) TO failed-job.
        APPEND VALUE #( %tky = ls-%tky %element-BatchNumber = if_abap_behv=>mk-on
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = |Batch { ls-BatchNumber } already has a job card.| ) )
          TO reported-job.
        CONTINUE.
      ENDIF.
      IF ls-Plant <> ls_bat-werks.
        APPEND VALUE #( %tky = ls-%tky ) TO failed-job.
        APPEND VALUE #( %tky = ls-%tky %element-Plant = if_abap_behv=>mk-on
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = |Batch { ls-BatchNumber } belongs to plant { ls_bat-werks }, not { ls-Plant }.| ) )
          TO reported-job.
        CONTINUE.
      ENDIF.

      " 3. The schedule must exist, be live, and be for the batch's dyed
      "    material in the same plant.
      SELECT SINGLE werks, matnr, delind
        FROM zpp_schedulen
        WHERE schno = @ls-ScheduleNumber
        INTO @DATA(ls_sch).
      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = ls-%tky ) TO failed-job.
        APPEND VALUE #( %tky = ls-%tky %element-ScheduleNumber = if_abap_behv=>mk-on
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = |Schedule { ls-ScheduleNumber } does not exist.| ) )
          TO reported-job.
        CONTINUE.
      ENDIF.
      IF ls_sch-delind = 'X'.
        APPEND VALUE #( %tky = ls-%tky ) TO failed-job.
        APPEND VALUE #( %tky = ls-%tky %element-ScheduleNumber = if_abap_behv=>mk-on
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = |Schedule { ls-ScheduleNumber } is deleted.| ) )
          TO reported-job.
        CONTINUE.
      ENDIF.
      IF ls_sch-matnr <> ls_bat-dye_code.
        APPEND VALUE #( %tky = ls-%tky ) TO failed-job.
        APPEND VALUE #( %tky = ls-%tky %element-ScheduleNumber = if_abap_behv=>mk-on
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = |Schedule { ls-ScheduleNumber } is for { ls_sch-matnr }, not the batch's dyed material { ls_bat-dye_code }.| ) )
          TO reported-job.
        CONTINUE.
      ENDIF.
      IF ls_sch-werks <> ls-Plant.
        APPEND VALUE #( %tky = ls-%tky ) TO failed-job.
        APPEND VALUE #( %tky = ls-%tky %element-ScheduleNumber = if_abap_behv=>mk-on
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = |Schedule { ls-ScheduleNumber } is for plant { ls_sch-werks }, not { ls-Plant }.| ) )
          TO reported-job.
        CONTINUE.
      ENDIF.

      " 4. The dyeing work centre is required and must exist in the plant; the
      "    winding work centre, if given, likewise. CRHD OBJTY 'A' = work centre.
      IF ls-DyeingWorkCenter IS INITIAL.
        APPEND VALUE #( %tky = ls-%tky ) TO failed-job.
        APPEND VALUE #( %tky = ls-%tky %element-DyeingWorkCenter = if_abap_behv=>mk-on
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = |A dyeing work centre is required.| ) )
          TO reported-job.
        CONTINUE.
      ENDIF.
      SELECT SINGLE objid FROM crhd
        WHERE objty = 'A' AND arbpl = @ls-DyeingWorkCenter AND werks = @ls-Plant
        INTO @DATA(lv_objid).
      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = ls-%tky ) TO failed-job.
        APPEND VALUE #( %tky = ls-%tky %element-DyeingWorkCenter = if_abap_behv=>mk-on
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = |Dyeing work centre { ls-DyeingWorkCenter } does not exist in plant { ls-Plant }.| ) )
          TO reported-job.
        CONTINUE.
      ENDIF.
      IF ls-WindingWorkCenter IS NOT INITIAL.
        SELECT SINGLE objid FROM crhd
          WHERE objty = 'A' AND arbpl = @ls-WindingWorkCenter AND werks = @ls-Plant
          INTO @lv_objid.
        IF sy-subrc <> 0.
          APPEND VALUE #( %tky = ls-%tky ) TO failed-job.
          APPEND VALUE #( %tky = ls-%tky %element-WindingWorkCenter = if_abap_behv=>mk-on
                          %msg = new_message_with_text(
                            severity = if_abap_behv_message=>severity-error
                            text     = |Winding work centre { ls-WindingWorkCenter } does not exist in plant { ls-Plant }.| ) )
            TO reported-job.
          CONTINUE.
        ENDIF.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.

  " Soft delete, the way ZJOB01N does it. The transaction also tries to release
  " the batch here, but its statement reads
  "   UPDATE zpp_batchn SET assigned = space WHERE batchno = wa_tab-jobno
  " comparing a batch number against a job number, so the flag almost never
  " cleared. That is why 15 batches in KSD are flagged ASSIGNED with no job card
  " against them (measured 2026-08-30). This one matches on the batch.
  METHOD markdeleted.
    READ ENTITIES OF zi_job IN LOCAL MODE
      ENTITY Job FIELDS ( BatchNumber ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_read).

    DATA lt_upd TYPE TABLE FOR UPDATE zi_job.
    LOOP AT lt_read INTO DATA(ls_read).
      APPEND VALUE #( %tky = ls_read-%tky DeletionFlag = 'X' ) TO lt_upd.
    ENDLOOP.

    MODIFY ENTITIES OF zi_job IN LOCAL MODE
      ENTITY Job UPDATE FIELDS ( DeletionFlag )
      WITH CORRESPONDING #( lt_upd ) REPORTED DATA(lt_rep).

    READ ENTITIES OF zi_job IN LOCAL MODE
      ENTITY Job ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_after).
    result = VALUE #( FOR ls IN lt_after ( %tky = ls-%tky %param = ls ) ).
  ENDMETHOD.

ENDCLASS.

" The additional save. Everything outside ZPP_JOBN happens here, after the
" managed runtime has written the job card itself.
CLASS lsc_job DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
    METHODS cleanup_finalize REDEFINITION.
ENDCLASS.

CLASS lsc_job IMPLEMENTATION.

  METHOD save_modified.

    " Created: the batch is now claimed.
    LOOP AT create-job INTO DATA(ls_new).
      IF ls_new-BatchNumber IS NOT INITIAL.
        UPDATE zpp_batchn SET assigned = 'X'
          WHERE batchno = @ls_new-BatchNumber.
      ENDIF.
    ENDLOOP.

    " Changed: release the batch the card moved away from, claim the new one.
    " Same two statements, same order, as MZ_PP_JOB_CARDNF01.
    LOOP AT update-job INTO DATA(ls_upd).
      READ TABLE lcl_job_buffer=>gt_old WITH KEY jobno = ls_upd-JobNumber
        INTO DATA(ls_old).
      DATA(lv_old_batch) = COND zpp_jobn-batchno( WHEN sy-subrc = 0 THEN ls_old-batchno ).

      " A job card that has just been marked deleted releases its batch and
      " claims nothing.
      IF ls_upd-DeletionFlag = 'X'.
        IF lv_old_batch IS NOT INITIAL.
          UPDATE zpp_batchn SET assigned = @space
            WHERE batchno = @lv_old_batch.
        ENDIF.
        CONTINUE.
      ENDIF.

      IF ls_upd-%control-BatchNumber = if_abap_behv=>mk-on
         AND lv_old_batch IS NOT INITIAL
         AND lv_old_batch <> ls_upd-BatchNumber.
        UPDATE zpp_batchn SET assigned = @space
          WHERE batchno = @lv_old_batch.
      ENDIF.

      IF ls_upd-BatchNumber IS NOT INITIAL.
        UPDATE zpp_batchn SET assigned = 'X'
          WHERE batchno = @ls_upd-BatchNumber.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD cleanup_finalize.
    CLEAR lcl_job_buffer=>gt_old.
  ENDMETHOD.

ENDCLASS.
