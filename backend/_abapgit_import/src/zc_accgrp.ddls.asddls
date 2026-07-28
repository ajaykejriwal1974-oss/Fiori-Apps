@EndUserText.label: 'Account Group Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['GroupCode']
define root view entity ZC_ACCGRP
  provider contract transactional_query
  as projection on ZI_ACCGRP
{
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
  key GroupCode,
      @Search.defaultSearchElement: true
      GroupText,
      SignReversal,
      _Accounts : redirected to composition child ZC_ACCGRP_ACC
}
