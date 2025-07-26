@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@VDM.viewType: #CONSUMPTION
@EndUserText.label: 'Inbound Invoice'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define root view entity ZC001_INVOICE
    as projection on ZI001_INVOICE as Header
{
    key Header.MessageId,
    Header.CompanyCode,
    Header.DocumentDate,
    Header.PostingDate,
    Header.ReferenceDocument,
    Header.Vendor,
    Header.DocumentCurrency,
    @Semantics.amount.currencyCode: 'DocumentCurrency'
    Header.InvoiceAmount,
    Header.PostingStatus,
    Header.StatusMessage,
    _Item : redirected to composition child ZC001_INVOICE_ITM
}
