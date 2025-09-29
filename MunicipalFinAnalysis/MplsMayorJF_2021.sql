select
YTDTotal.RecentDate as Date,
format('%s\n%s' ,YTDTotal.Name,YTDTotal.FullAddress )  Name,
YTDTotal.Employer  Employer,
 substr(FulladdressFormatted, 1, instr(FulladdressFormatted , '|') -1) Address1,
  initcap( substr(FulladdressFormatted, instr(FulladdressFormatted , '|' ) + 1, (instr(FulladdressFormatted , '||') - instr(FulladdressFormatted , '|') -1))) City,
  substr(FulladdressFormatted, instr(FulladdressFormatted , '|| ' ) + 2, (instr(FulladdressFormatted , '|||') - instr(FulladdressFormatted , '||') -2)) ZipCode,
  substr(FulladdressFormatted, -2, 2) State ,
'' Description_of_In_Kind,
PreTotal.TotalAmount as Previous_total_for_the_year ,
PreGenTotal.TotalAmount   Received_this_period,
'' Value_of_in_kind,
YTDTotal.TotalAmount   Total_from_source_year_to_date,
YTDTotal.Name FullName
from
-- Get total for year to date for the filling period that you want to report on
( select
Name,
MAX(FullAddress) FullAddress,
MAX(FulladdressFormatted) FulladdressFormatted,
max(Employer) Employer,
max(email) Email,
max(Phone) Phone,
max(Date) RecentDate,
Count(Distinct Type) CountDonationType,
count(Name) as CountDonations,
sum(Amount) TotalAmount
from `campaignanalytics-182101.MNHenMplsMayorJacobF.JFMplsMayorDonationAll_Process`
where date between  '2021-01-01' and '2021-12-31'
group by 1
having sum(Amount) > 100 ) YTDTotal join
-- Get total for the reporting period
( select
Name,
MAX(FullAddress) FullAddress,
MAX(FulladdressFormatted) FulladdressFormatted,
max(Employer) Employer,
max(email) Email,
max(Phone) Phone,
max(Date) RecentDate,
Count(Distinct Type) CountDonationType,
count(Name) as CountDonations,
sum(Amount) TotalAmount
from `campaignanalytics-182101.MNHenMplsMayorJacobF.JFMplsMayorDonationAll_Process`
where date between '2021-10-20' and '2021-12-31'
group by 1 ) PreGenTotal on YTDTotal.name = PreGenTotal.name
-- Get total for the previous reporting period
left outer join
( select
Name,
MAX(FullAddress) FullAddress,
MAX(FulladdressFormatted) FulladdressFormatted,
max(Employer) Employer,
max(email) Email,
max(Phone) Phone,
max(Date) RecentDate,
Count(Distinct Type) CountDonationType,
count(Name) as CountDonations,
sum(Amount) TotalAmount
from `campaignanalytics-182101.MNHenMplsMayorJacobF.JFMplsMayorDonationAll_Process`
where date between  '2021-01-01' and '2021-10-19'
group by 1 ) PreTotal on  YTDTotal.name = PreTotal.name
where YTDTotal.name not in (select distinct FullName from  `campaignanalytics-182101.MNHenMplsMayorJacobF.JFMplsMayorDonationAll_Excep_Name`
           UNION ALL
           select distinct name from `campaignanalytics-182101.MNHenMplsMayorJacobF.JFMplsMayorDonationAll_Excep_MultiInd`)
order by substring(trim(YTDTotal.Name ) , instr(trim(YTDTotal.Name ),' ',-1)+1, (length(YTDTotal.Name ) - instr(trim(YTDTotal.Name ),' ',-1))) asc