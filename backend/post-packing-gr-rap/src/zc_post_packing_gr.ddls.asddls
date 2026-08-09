@EndUserText.label: 'Post Packing & GR - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_PostPackGr
  provider contract transactional_query
  as projection on ZI_PostPackGr
{
  key HandlingUnit,
      PackagingMaterial,
      Reference
}
