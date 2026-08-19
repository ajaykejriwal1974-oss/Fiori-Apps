@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Account Group Master - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['GroupCode']
define root view entity ZI_ACCGRP
  as select from zsol_accgrp
  composition [0..*] of ZI_ACCGRP_ACC as _Accounts
{
  key zzsol_grp as GroupCode,
      text50    as GroupText,
      zsign_rev as SignReversal,
      _Accounts
}
