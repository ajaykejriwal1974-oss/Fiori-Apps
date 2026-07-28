@EndUserText.label: 'Post Packing & GR - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_POST_PACKING_GR
  provider contract transactional_query
  as projection on ZI_POST_PACKING_GR
{
  @Search.defaultSearchElement: true
  key HandlingUnit,
      PackagingMaterial,
      Reference
}
