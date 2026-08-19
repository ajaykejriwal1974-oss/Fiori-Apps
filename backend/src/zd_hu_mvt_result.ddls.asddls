@EndUserText.label: 'Post HU Goods Movement - action result'
define abstract entity ZD_HU_MVT_RESULT
{
  MaterialDocument     : abap.char(10);
  MaterialDocumentYear : abap.numc(4);
  Message              : abap.string;
}
