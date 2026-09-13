@EndUserText.label: 'Value help - Component Type'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.dataCategory: #TEXT
// Value help for ComponentType on the recipe. ZPP_RECEIPE has a foreign key to
// ZPP_COMP and the field is a code an operator has to type from memory - the
// only place Recipe Master can silently go wrong. Every other coded field on
// that view already has a help.
//
// NEW OBJECT: create as a Data Definition in package ZKGPL_FIORI on KSDK906759.
define view entity ZI_VH_COMP_TYPE
  as select from zpp_comp
{
      @EndUserText.label: 'Component Type'
      @Search.defaultSearchElement: true
      @ObjectModel.text.element: ['ComponentTypeName']
  key comp_type as ComponentType,
      @EndUserText.label: 'Description'
      @Semantics.text: true
      comp_desc as ComponentTypeName
}
