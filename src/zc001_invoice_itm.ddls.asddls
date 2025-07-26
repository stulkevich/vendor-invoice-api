@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@VDM.viewType: #CONSUMPTION
@EndUserText.label: 'Inbound Invoice Item'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZC001_INVOICE_ITM
    as projection on ZI001_INVOICE_ITM as Item
{
    key Item.MessageID,
    key Item.ItemID,
    Item.PurchaseOrder,
    Item.PurchaseOrderItem,
    Item.DocumentCurrency,
    @Semantics.amount.currencyCode: 'DocumentCurrency'
    Item.ItemAmount,
    _Header : redirected to parent ZC001_INVOICE
}
