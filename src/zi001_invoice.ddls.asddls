@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Inbound Invoice'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define root view entity ZI001_INVOICE 
    as select from Z001_INVOICE
  
    composition [0..*] of ZI001_INVOICE_ITM as _Item
{
    key message_id as MessageId,
    bukrs as CompanyCode,
    bldat as DocumentDate,
    budat as PostingDate,
    xblnr as ReferenceDocument,
    lifnr as Vendor,
    waers as DocumentCurrency,
    @Semantics.amount.currencyCode: 'DocumentCurrency'
    rmwwr as InvoiceAmount,
    status as PostingStatus,
    status_message as StatusMessage,
    _Item
}
