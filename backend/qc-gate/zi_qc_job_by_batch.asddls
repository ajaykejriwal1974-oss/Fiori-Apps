@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'QC: job card per plant batch'
// ZPP_JOBN is keyed on JOBNO alone, so a plant batch can in principle carry
// more than one open job card. In plant 2002 JOBNO equals BATCHNO one for one -
// checked, 22 job cards against 22 batches - so this aggregation is a no-op
// today. It stays because the table permits what the data happens not to do,
// and JobCardCount makes the day that changes visible instead of silent.
define view entity ZI_QC_JOB_BY_BATCH
  as select from zpp_jobn
{
  key werks        as Plant,
  key batchno      as BatchNumber,
      max( jobno ) as JobCard,
      count( * )   as JobCardCount
}
where delind = ' '
group by werks,
         batchno
