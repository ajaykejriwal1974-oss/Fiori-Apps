@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Customer Master Register (ZCUST)'
@Analytics: { dataCategory: #CUBE, dataExtraction.enabled: true }
@Metadata.allowExtensions: true
define view entity ZI_CUSTOMER_MASTER
  as select from    knvv as sa
    left outer join  kna1 as c   on  c.kunnr = sa.kunnr
    left outer join  adrc as ad  on  ad.addrnumber = c.adrnr
    left outer join  knvp as ag  on  ag.kunnr = sa.kunnr
                                  and ag.vkorg = sa.vkorg
                                  and ag.vtweg = sa.vtweg
                                  and ag.spart = sa.spart
                                  and ag.parvw = 'ZA'
    left outer join  kna1 as agc on  agc.kunnr = ag.kunn2
{
  key sa.kunnr          as Customer,
  key sa.vkorg          as SalesOrg,
  key sa.vtweg          as DistributionChannel,
  key sa.spart          as Division,
      c.name1           as CustomerName,
      c.name2           as CustomerName2,
      c.sortl           as SearchTerm,
      ad.street         as Street,
      ad.post_code1     as PostalCode,
      ad.city1          as City,
      ad.city2          as District,
      c.adrnr           as AddressNumber,
      c.stcd3           as GSTIN,
      c.j_1icstno       as CSTNumber,
      c.j_1ilstno       as LSTNumber,
      c.j_1ipanno       as PANNumber,
      c.erdat           as CreatedOn,
      sa.zterm          as SalesPaymentTerms,
      agc.name1         as SalesAgentName,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Record Count'
      cast( 1 as abap.int4 ) as RecordCount
}
