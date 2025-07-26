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
      entity           TYPE STRUCTURE FOR CREATE ZI001_INVOICE.

    LOOP AT entities INTO entity.
      TRY.
          entity-MessageId = cl_uuid_factory=>create_system_uuid( )->create_uuid_c32( ).
          APPEND VALUE #(
            %cid      = entity-%cid
            %key      = entity-%key ) TO mapped-header.
        CATCH cx_uuid_error.
          APPEND VALUE #(
            %cid      = entity-%cid
            %key      = entity-%key ) TO failed-header.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

  METHOD earlynumbering_cba_Item.
    DATA:
      entity  TYPE STRUCTURE FOR CREATE ZI001_INVOICE\\Header\_Item,
      counter TYPE i.

    LOOP AT entities INTO entity.
      DATA(lt_items) = entity-%target.
      LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<ls_item>).
        counter += 1.
        <ls_item>-ItemID = counter.
        APPEND CORRESPONDING #( <ls_item> ) TO mapped-item.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD post.
  ENDMETHOD.

  METHOD PostingStatus.
  ENDMETHOD.

ENDCLASS.
