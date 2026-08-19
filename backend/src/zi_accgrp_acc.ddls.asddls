@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Account Group Assignment - Interface'
@Metadata.allowExtensions: true
define view entity ZI_ACCGRP_ACC
  as select from zsol_acc_grp
  association to parent ZI_ACCGRP as _Group on $projection.GroupCode = _Group.GroupCode
{
  key zzsol_grp as GroupCode,
  key racct     as GLAccount,
      _Group
}
