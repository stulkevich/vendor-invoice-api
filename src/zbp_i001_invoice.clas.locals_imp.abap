CLASS lcl_invoice_processing DEFINITION FINAL.
  PUBLIC SECTION.
    TYPES:
      BEGIN OF sts_invoice_full_status,
        PostingStatus TYPE zi001_invoice-PostingStatus,
        StatusMessage TYPE zi001_invoice-StatusMessage,
      END OF sts_invoice_full_status,
      sts_invoice_header TYPE STRUCTURE FOR CREATE zi001_invoice,
      stt_invoice_item   TYPE TABLE FOR CREATE zi001_invoice_itm.
    CONSTANTS:
      BEGIN OF sc_Posting_Status,
        created TYPE ZE001_INV_status VALUE 'CREATED',
        posted  TYPE ZE001_INV_status VALUE 'POSTED',
      END OF sc_Posting_Status.

    CLASS-METHODS:
      post_invoice
        IMPORTING
          is_invoice_header TYPE sts_invoice_header
          it_invoice_item   TYPE stt_invoice_item
        RETURNING
          VALUE(rs_status)  TYPE sts_invoice_full_status,
      post_invoice_mock
        IMPORTING
          is_invoice_header TYPE sts_invoice_header
          it_invoice_item   TYPE stt_invoice_item
        RETURNING
          VALUE(rs_status)  TYPE sts_invoice_full_status.
ENDCLASS.

CLASS lcl_invoice_processing IMPLEMENTATION.
  METHOD post_invoice.
*    CONSTANTS:
*      lc_glaccount_default  TYPE saknr VALUE '0000400000',
*      lc_costcenter_default TYPE kostl VALUE 'DUMMY'.
*
*    DATA ls_invoice TYPE STRUCTURE FOR ACTION IMPORT i_supplierinvoicetp~create.
*    DATA lt_invoice TYPE TABLE FOR ACTION IMPORT i_supplierinvoicetp~create.
*
*    CHECK is_invoice_header-PostingStatus <> sc_Posting_Status-posted.
*
*    rs_status-PostingStatus = sc_Posting_Status-created.
*
*    TRY.
*        DATA(lv_cid) = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ).
*      CATCH cx_uuid_error.
*        MESSAGE e001(Z001) INTO rs_status-statusmessage.
*    ENDTRY.
*
*    ls_invoice-%cid = lv_cid.
*    ls_invoice-%param-companycode = is_invoice_header-CompanyCode.
*    ls_invoice-%param-invoicingparty = is_invoice_header-Vendor.
*    ls_invoice-%param-postingdate = is_invoice_header-PostingDate.
*    ls_invoice-%param-documentdate = is_invoice_header-DocumentDate.
*    ls_invoice-%param-documentcurrency = is_invoice_header-DocumentCurrency.
*    ls_invoice-%param-invoicegrossamount = is_invoice_header-InvoiceAmount.
*    ls_invoice-%param-taxiscalculatedautomatically = abap_true.
*    ls_invoice-%param-supplierinvoiceidbyinvcgparty = is_invoice_header-ReferenceDocument.
*
*    LOOP AT it_invoice_item ASSIGNING FIELD-SYMBOL(<ls_invoice_item>).
*      ls_invoice-%param-_glitems = VALUE #(
*        ( supplierinvoiceitem = <ls_invoice_item>-ItemID
*          debitcreditcode = cl_mmiv_rap_ext_c=>debitcreditcode-debit
*          glaccount = lc_glaccount_default
*          companycode = is_invoice_header-CompanyCode
*          documentcurrency = <ls_invoice_item>-DocumentCurrency
*          supplierinvoiceitemamount = <ls_invoice_item>-ItemAmount
*          costcenter = lc_costcenter_default )
*      ).
*
*      INSERT ls_invoice INTO TABLE lt_invoice.
*
*      "Register the action
*      MODIFY ENTITIES OF i_supplierinvoicetp
*        ENTITY supplierinvoice
*        EXECUTE create FROM lt_invoice
*        FAILED DATA(ls_failed)
*        REPORTED DATA(ls_reported)
*        MAPPED DATA(ls_mapped).
*
*      IF ls_failed IS NOT INITIAL.
*        DATA lo_message TYPE REF TO if_message.
*        lo_message = ls_reported-supplierinvoice[ 1 ]-%msg.
*        rs_status-statusmessage = lo_message->get_text( ).
*      ENDIF.
*
*      "Execution the action
*      COMMIT ENTITIES
*       RESPONSE OF i_supplierinvoicetp
*       FAILED DATA(ls_commit_failed)
*       REPORTED DATA(ls_commit_reported).
*
*      IF ls_commit_reported IS NOT INITIAL.
*        LOOP AT ls_commit_reported-supplierinvoice ASSIGNING FIELD-SYMBOL(<ls_invoice>).
*          IF <ls_invoice>-supplierinvoice IS NOT INITIAL AND
*             <ls_invoice>-supplierinvoicefiscalyear IS NOT INITIAL.
*            MESSAGE s002(Z001) WITH <ls_invoice>-supplierinvoice <ls_invoice>-supplierinvoicefiscalyear INTO rs_status-statusmessage.
*            rs_status-PostingStatus = sc_Posting_Status-posted.
*            EXIT. "Single line expected
*          ENDIF.
*        ENDLOOP.
*      ENDIF.
*
*      IF ls_commit_failed IS NOT INITIAL.
*        LOOP AT ls_commit_reported-supplierinvoice ASSIGNING <ls_invoice>.
*          rs_status-statusmessage = <ls_invoice>-%msg-text.
*          EXIT. "Single line expected
*        ENDLOOP.
*      ENDIF.
  ENDMETHOD.

  METHOD post_invoice_mock.
    "CHECK is_invoice_header-PostingStatus <> sc_Posting_Status-posted.

    IF is_invoice_header-CompanyCode = 'MY01'.
      rs_status-PostingStatus = sc_Posting_Status-posted.
      MESSAGE s002(z001) WITH 'MockDoc1' '2025' INTO rs_status-statusmessage.
    ELSE.
      rs_status-PostingStatus = sc_Posting_Status-created.
      MESSAGE e003(z001) WITH is_invoice_header-CompanyCode INTO rs_status-statusmessage.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_Header DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE Header.

    METHODS earlynumbering_cba_Item FOR NUMBERING
      IMPORTING entities FOR CREATE Header\_Item.

    METHODS post FOR MODIFY
      IMPORTING keys FOR ACTION Header~post RESULT result.

    METHODS PostingStatus FOR DETERMINE ON SAVE
      IMPORTING keys FOR Header~PostingStatus.

ENDCLASS.

CLASS lhc_Header IMPLEMENTATION.

  METHOD earlynumbering_create.
    DATA:
      ls_entity           TYPE STRUCTURE FOR CREATE zi001_invoice.

    LOOP AT entities INTO ls_entity.
      TRY.
          ls_entity-MessageId = cl_uuid_factory=>create_system_uuid( )->create_uuid_c32( ).
          APPEND VALUE #(
            %cid      = ls_entity-%cid
            %key      = ls_entity-%key ) TO mapped-header.
        CATCH cx_uuid_error.
          APPEND VALUE #(
            %cid      = ls_entity-%cid
            %key      = ls_entity-%key ) TO failed-header.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

  METHOD earlynumbering_cba_Item.
    DATA:
      ls_entity  TYPE STRUCTURE FOR CREATE zi001_invoice\\Header\_Item,
      lv_counter TYPE i.

    LOOP AT entities INTO ls_entity.
      DATA(lt_items) = ls_entity-%target.
      LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<ls_item>).
        lv_counter += 1.
        <ls_item>-ItemID = lv_counter.
        APPEND CORRESPONDING #( <ls_item> ) TO mapped-item.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD post.
    DATA:
      lt_header_upd  TYPE TABLE FOR UPDATE zi001_invoice,
      ls_header      TYPE lcl_invoice_processing=>sts_invoice_header,
      lt_items       TYPE lcl_invoice_processing=>stt_invoice_item.

    READ ENTITIES OF zi001_invoice IN LOCAL MODE
      ENTITY header
      ALL FIELDS WITH
      CORRESPONDING #( keys )
      RESULT DATA(headers).
    ASSIGN headers[ 1 ] TO FIELD-SYMBOL(<ls_header>).
    IF sy-subrc = 0.
      ls_header = CORRESPONDING #( <ls_header> ).
    ENDIF.

    READ ENTITIES OF zi001_invoice IN LOCAL MODE
      ENTITY item
      ALL FIELDS WITH
      CORRESPONDING #( keys )
      RESULT DATA(items).
    lt_items = CORRESPONDING #( items ).


    DATA(ls_result) = lcl_invoice_processing=>post_invoice_mock(
      is_invoice_header = ls_header
      it_invoice_item   = lt_items ).

    IF ls_result IS NOT INITIAL.
      MODIFY ENTITIES OF zi001_invoice IN LOCAL MODE
        ENTITY header
        UPDATE FIELDS ( PostingStatus StatusMessage )
        WITH VALUE #( FOR key IN keys
          ( %tky = key-%tky
            PostingStatus = ls_result-PostingStatus
            StatusMessage = ls_result-StatusMessage
            %control = VALUE #(
              PostingStatus = if_abap_behv=>mk-on
              StatusMessage = if_abap_behv=>mk-on ) ) )
        FAILED failed
        REPORTED reported.
    ENDIF.

    APPEND INITIAL LINE TO result ASSIGNING FIELD-SYMBOL(<ls_result>).
    <ls_result>-MessageId = <ls_header>-MessageId.
    <ls_result>-%param = CORRESPONDING #( <ls_header> ).

  ENDMETHOD.

  METHOD PostingStatus.
    DATA:
      lt_reported_upd TYPE TABLE FOR UPDATE zi001_invoice,
      ls_header       TYPE lcl_invoice_processing=>sts_invoice_header,
      lt_items        TYPE lcl_invoice_processing=>stt_invoice_item.

    READ ENTITIES OF zi001_invoice IN LOCAL MODE
      ENTITY header
      ALL FIELDS WITH
      CORRESPONDING #( keys )
      RESULT DATA(headers).
    ASSIGN headers[ 1 ] TO FIELD-SYMBOL(<ls_header>).
    IF sy-subrc = 0.
      ls_header = CORRESPONDING #( <ls_header> ).
    ENDIF.

    READ ENTITIES OF zi001_invoice IN LOCAL MODE
      ENTITY item
      ALL FIELDS WITH
      CORRESPONDING #( keys )
      RESULT DATA(items).
    lt_items = CORRESPONDING #( items ).


    DATA(ls_result) = lcl_invoice_processing=>post_invoice_mock(
      is_invoice_header = ls_header
      it_invoice_item   = lt_items ).

    MODIFY ENTITIES OF zi001_invoice IN LOCAL MODE
      ENTITY header
      UPDATE FIELDS ( PostingStatus StatusMessage )
      WITH VALUE #( FOR key IN keys
        ( %tky = key-%tky
          PostingStatus = ls_result-PostingStatus
          StatusMessage = ls_result-StatusMessage
          %control = VALUE #(
            PostingStatus = if_abap_behv=>mk-on
            StatusMessage = if_abap_behv=>mk-on ) ) )
      REPORTED DATA(reported_upd).

    reported = CORRESPONDING #( DEEP reported_upd ).
  ENDMETHOD.

ENDCLASS.
