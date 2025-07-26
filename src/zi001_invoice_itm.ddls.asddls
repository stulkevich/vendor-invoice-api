@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Inbound Invoice Item'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZI001_INVOICE_ITM
    as select from Z001_INVOICE_ITM as Item
  
    association to parent ZI001_INVOICE as _Header on $projection.MessageID = _Header.MessageId
{
    key Item.message_id as MessageID,
    key Item.buzei      as ItemID,
    Item.ebeln          as PurchaseOrder,
    Item.ebelp          as PurchaseOrderItem,
    _Header.DocumentCurrency as DocumentCurrency,
    @Semantics.amount.currencyCode: 'DocumentCurrency'
    Item.wrbtr          as ItemAmount,
    _Header
}
