@EndUserText.label: 'Account Group Assignment - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity ZC_ACCGRP_ACC
  as projection on ZI_ACCGRP_ACC
{
  key GroupCode,
  key GLAccount,
      _Group : redirected to parent ZC_ACCGRP
}
