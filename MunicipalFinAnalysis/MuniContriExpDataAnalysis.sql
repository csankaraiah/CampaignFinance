/* 
Analyze hen county candidate data 
*/ 


/* This file provides analysis of contribution data*/

SELECT candidate_name_, round(sum(Total_From_Source_Year_to_Date_	),2) FROM  `campaignanalytics-182101.Munidata.MuniHenContriData` 
group by candidate_name_
order by 2 desc

--employer counts and dollars 
SELECT Contributors_Employer_ , round(sum(Total_From_Source_Year_to_Date_	),2) amtYTD, sum( Received_This_Period_) amtThisPeriod, count(*)  
FROM  `campaignanalytics-182101.Munidata.MuniHenContriData`
group by Contributors_Employer_
order by 4 desc

--- Combining with candidate master data 
SELECT distinct cand.* 
FROM `campaignanalytics-182101.Munidata.MuniHenContriData` contri
join `campaignanalytics-182101.Munidata.MuniHenCandMst` cand on trim(contri.CandidateName) = trim(cand.Candidate_name)


-- Candidate and contributor analysis
SELECT contri.CandidateName , extract(year from dateRecd) as yr, ContributorName, city, State, ContributorsEmployer, 
round(sum( TotalFromSourceYeartoDate ),2) amtYTD, round(sum( ReceivedThisPeriod ),2) amtThisPeriod, count(*) contribCnt
FROM `campaignanalytics-182101.Munidata.MuniHenContriData` contri
join `campaignanalytics-182101.Munidata.MuniHenCandMst` cand on trim(contri.CandidateName) = trim(cand.Candidate_name)
where trim(contri.candidatename) = 'Reich, Kevin'
group by  contri.CandidateName , yr , ContributorName, city, State, ContributorsEmployer
order by contribCnt desc



SELECT contri.CandidateName , extract(year from dateRecd) as Yr, 
round(sum( cast(REGEXP_EXTRACT(ReceivedThisPeriod, r'[\d\.\d]+') as float64) ),2) ContribReceivedAmt,
round(sum( cast(REGEXP_EXTRACT(ValueofinKindDonation, r'[\d\.\d]+') as float64) ),2) ValueInKindDonationAmt,
round(sum( cast(REGEXP_EXTRACT(TotalFromSourceYeartoDate, r'[\d\.\d]+') as float64) ),2) TotalYTDContribAmt, 
count(*) TotalContribCnt, 
FROM `campaignanalytics-182101.Munidata.MuniHenContriData12202020` contri
join `campaignanalytics-182101.Munidata.MuniHenCandMst` cand on trim(contri.CandidateName) = trim(cand.Candidate_name)
where cand.Office = 'Council Member' 
and cand.Location = 'Minneapolis'
--where trim(contri.candidatename) = 'Reich, Kevin'
group by  contri.CandidateName , yr 
order by 1 



SELECT contri.CandidateName , extract(year from dateRecd) as Yr, 
round(sum( ReceivedThisPeriod),2) ContribReceivedAmt,
round(sum( ValueofinKindDonation),2) ValueInKindDonationAmt,
round(sum( cast(REGEXP_EXTRACT(TotalFromSourceYeartoDate, r'[\d\.\d]+') as float64) ),2) TotalYTDContribAmt, 
count(*) TotalContribCnt, 
FROM `campaignanalytics-182101.Munidata.MuniHenContriData12312020` contri
join `campaignanalytics-182101.Munidata.MuniHenCandMst` cand on trim(contri.CandidateName) = trim(cand.Candidate_name)
where 
--cand.Office = 'Council Member' and 
cand.Location = 'Minneapolis'
--where trim(contri.candidatename) = 'Reich, Kevin' 
group by  contri.CandidateName , yr 
order by 1 ,2


SELECT contri.CandidateName , round(sum(if(extract(year from dateRecd) in (2014,2015,2016,2017), TotalFromSourceYeartoDate ,0))) Election2017, 
 round(sum(if(extract(year from dateRecd) in (2018,2019,2020), TotalFromSourceYeartoDate ,0))) Election2021,
round(sum( TotalFromSourceYeartoDate ),2) ContribAmt, round(avg( TotalFromSourceYeartoDate ),2) AvgContribAmt, count(*) TotalContribCnt, 
FROM `campaignanalytics-182101.Munidata.MuniHenContriData` contri
join `campaignanalytics-182101.Munidata.MuniHenCandMst` cand on trim(contri.CandidateName) = trim(cand.Candidate_name)
where cand.Office = 'Council Member' 
and cand.Location = 'Minneapolis'
--where trim(contri.candidatename) = 'Reich, Kevin'
group by  contri.CandidateName 
order by 1 











/************************************************************ 
 Queries to analyze contribution data so that we can parse out master list for donors. 

*************************************************************/




-- Summary by contribution category , percentage for overall contribution for a election cycle which is from 2014 to 2017

SELECT trim(contri.candidatename),
`campaignanalytics-182101.dq.dq_B_ContriCategory`(Contri.ContributorsEmployer, Contri.ContributorName)  ContritutionCategory,
ROUND(( ( ROUND(SUM(ReceivedThisPeriod),2) + ROUND(SUM(Coalesce(ValueofinKindDonation,0)),2))/ Avg(TotalDonation) * 100),2) DonationPercent,
  ROUND(SUM(ReceivedThisPeriod),2) ReceivedThisPeriod,
  Coalesce(ROUND(SUM(ValueofinKindDonation),2),0) ValueofinKindDonation,
  Avg(TotalDonation) TotalDonation
FROM
  `campaignanalytics-182101.Munidata.MuniHenContriData12312020` contri
JOIN (select candidatemst.* from 
`campaignanalytics-182101.Munidata.MuniHenCandMst` candidatemst join 
(select Candidate_name, max(Registration_date)  maxRegistrationDt
from   `campaignanalytics-182101.Munidata.MuniHenCandMst` group by  Candidate_name) candmax 
on candmax.Candidate_name = candidatemst.Candidate_name and maxRegistrationDt = candidatemst.Registration_date ) cand ON TRIM(contri.CandidateName) = TRIM(cand.Candidate_name)
JOIN (Select trim(CandidateName) CandName ,   ROUND(SUM(ReceivedThisPeriod),2) + ROUND(SUM(Coalesce(ValueofinKindDonation,0)),2) TotalDonation 
      from `campaignanalytics-182101.Munidata.MuniHenContriData12312020` 
      where EXTRACT(year FROM    dateRecd) in (2014,2015,2016,2017)
      Group by CandidateName) on TRIM(contri.CandidateName) = CandName 
where cand.Location = 'Minneapolis' --and
--trim(contri.candidatename) = 'Frey, Jacob'
and EXTRACT(year FROM dateRecd) in (2014,2015,2016,2017)
group by 1,2
order by 1,2




-- Data for contribution from associations and finding pattern in them

SELECT 
trim(Contri.ContributorName) ContributorName,
ROUND(( ( ROUND(SUM(ReceivedThisPeriod),2) + ROUND(SUM(Coalesce(ValueofinKindDonation,0)),2))/ Avg(TotalDonation) * 100),2) DonationPercent,
  ROUND(SUM(ReceivedThisPeriod),2) ReceivedThisPeriod,
  Coalesce(ROUND(SUM(ValueofinKindDonation),2),0) ValueofinKindDonation,
  Avg(TotalDonation) TotalDonation
FROM
  `campaignanalytics-182101.Munidata.MuniHenContriData12312020` contri
JOIN (select candidatemst.* from 
`campaignanalytics-182101.Munidata.MuniHenCandMst` candidatemst join 
(select Candidate_name, max(Registration_date)  maxRegistrationDt
from   `campaignanalytics-182101.Munidata.MuniHenCandMst` group by  Candidate_name) candmax 
on candmax.Candidate_name = candidatemst.Candidate_name and maxRegistrationDt = candidatemst.Registration_date ) cand ON TRIM(contri.CandidateName) = TRIM(cand.Candidate_name)
JOIN (Select trim(CandidateName) CandName ,   ROUND(SUM(ReceivedThisPeriod),2) + ROUND(SUM(Coalesce(ValueofinKindDonation,0)),2) TotalDonation 
      from `campaignanalytics-182101.Munidata.MuniHenContriData12312020` 
      where EXTRACT(year FROM    dateRecd) in (2014,2015,2016,2017)
      Group by CandidateName) on TRIM(contri.CandidateName) = CandName 
where cand.Location = 'Minneapolis' --and
--trim(contri.candidatename) = 'Frey, Jacob'
and `campaignanalytics-182101.dq.dq_B_ContriCategory`(Contri.ContributorsEmployer, Contri.ContributorName) = 'Association'
and EXTRACT(year FROM dateRecd) in (2014,2015,2016,2017)
group by 1
order by 1



-- Query that further refines the data to associations specific contribution data 
-- This query was used to create MuniHenAssocMst table. I have filtered this for Barb johnson for now

create table `campaignanalytics-182101.Munidata.MuniHenAssocMst` 
as (
SELECT 
trim(replace(replace(contri.contributorName,",",""),".","")) AssociationName, 
max(trim(concat(contri.contributorAddress," ",contri.City, " " , contri.State ))) AssociationFullAddr,
( ROUND(SUM(Coalesce(ReceivedThisPeriod,0)),2) + ROUND(SUM(Coalesce(ValueofinKindDonation,0)),2)) DonationTotal,
max(Previoustotalforthisyear) PreviousYrDonation,
max(TotalFromSourceYeartoDate )  TotalFromTheSource,
  count(distinct contri.candidatename) CountOfCandidate
FROM
  `campaignanalytics-182101.Munidata.MuniHenContriData12312020` contri
JOIN (select candidatemst.* from `campaignanalytics-182101.Munidata.MuniHenCandMst` candidatemst join 
              (select Candidate_name, max(Registration_date)  maxRegistrationDt
        from   `campaignanalytics-182101.Munidata.MuniHenCandMst` group by  Candidate_name) candmax 
on candmax.Candidate_name = candidatemst.Candidate_name and maxRegistrationDt = candidatemst.Registration_date ) cand ON TRIM(contri.CandidateName) = TRIM(cand.Candidate_name)
where cand.Location = 'Minneapolis' and
-- If we want to broaden this analysis we need to remove this condition 
--trim(contri.candidatename) = 'Johnson, Barbara' and 
trim(replace(replace(contri.contributorName,",",""),".","")) not in ('Association')
and `campaignanalytics-182101.dq.dq_B_ContriCategory`(Contri.ContributorsEmployer, Contri.ContributorName) = 'Association'
group by 1)


/* 
Now since we have assoiation master that has distinct different names for association Contributors we will use fuzzy matching to match this 
to a unique master association name. here are the 3 sources we are going to use 
1. Match this name with MN CFB lobbying entity data
2. Match this name with MN CFB PAC & Unions data 
3. Match this name with Parties data (TBD) 

If there is no match found then leverage Google API to get place id & place details that provides name as google recognize it. Have created a separate table that takes unique 
contribution name and does google place API lookup to get details and is stored in table `campaignanalytics-182101.Munidata.MuniHenAssocGoogleDtlETL`
--- Associations unique list with details 

*/

SELECT 
AssocMst.AssociationName ,
replace (replace(replace (AssocMst.AssociationName,'Political Fund',''),'Politcal Fund',''),'PAC','') AssocMstName,
AssocMatch.contriAssoc ,
AssocGoogle.Name GoogleAssocName,
AssocLobbyEnt.LobbyEntity_name LobbyEntityName,
AssocPACUnion.PACUnion_name PACUnionName, 
AssocMst.AssociationFullAddr ,
AssocMst.DonationTotal ,
AssocMst.CountOfCandidate ,
AssocMatch.MatchingAssoc ,
AssocMatch.MatchSource ,
AssocMatch.Matchlevel,
AssocGoogle.FormattedFullAddress ,
AssocGoogle.FormattedPhoneNumber ,
AssocLobbyEnt.LobbyEntity_assocName ,
AssocLobbyEnt.LobbyEntity_address1 ,
AssocLobbyEnt.LobbyEntity_city ,
AssocLobbyEnt.LobbyEntity_state ,
AssocLobbyEnt.LobbyEntity_zipCode ,
AssocLobbyEnt.LobbyEntity_contactName ,
AssocLobbyEnt.LobbyEntity_contactPhoneNumber ,
AssocLobbyEnt.LobbyEntity_website ,
AssocPACUnion.PACUnion_Address1 ,
AssocPACUnion.PACUnion_City ,
AssocPACUnion.PACUnion_State ,
AssocPACUnion.PACUnion_ZipCode ,
AssocPACUnion.PACUnion_Role1 ,
AssocPACUnion.PACUnion_Role1Address1 ,
AssocPACUnion.PACUnion_Role1City ,
AssocPACUnion.PACUnion_Role1City ,
AssocPACUnion.PACUnion_Role1EmailId ,
AssocPACUnion.PACUnion_Role1Name ,
AssocPACUnion.PACUnion_Role1PhoneNumber ,
AssocPACUnion.PACUnion_Website 
FROM `campaignanalytics-182101.Munidata.MuniHenAssocMst` AssocMst 
left outer join `campaignanalytics-182101.Munidata.MuniHenAssocMatchETL` AssocMatch on replace (replace(replace (AssocMst.AssociationName,'Political Fund',''),'Politcal Fund',''),'PAC','')  = AssocMatch.contriAssoc  
left outer join (SELECT distinct 
                        Name,
                        website,
                        FormattedFullAddress, 
                        FormattedPhoneNumber
                        FROM `campaignanalytics-182101.Munidata.MuniHenAssocGoogleDtlETL` 
                        order by 2 ) AssocGoogle on ( AssocMatch.MatchingAssoc = AssocGoogle.Name and AssocMatch.MatchSource = 'GoogleAssocPlaceDtl')
left outer join `campaignanalytics-182101.MNCFBDatasets.MNCFBLobbyingEntityMst` AssocLobbyEnt on ( AssocMatch.MatchingAssoc = AssocLobbyEnt.LobbyEntity_name and AssocMatch.MatchSource = 'MNCFB_LobbyEntity')
left outer join `campaignanalytics-182101.MNCFBDatasets.MNCFBPACUnionMst`  AssocPACUnion on ( AssocMatch.MatchingAssoc = AssocPACUnion.PACUnion_name and AssocMatch.MatchSource = 'MNCFB_PACUnion')
order by 1






--once the data was extract using this SQL there was a extensice mannual matching and cleaning that was done to get master list of associations
-- Overall from a starting point of 200+ records it boiled down to approx. 80 association that ahve contributed to municipal elections in Minneapolis. 
-- This final file is loaded to bigquery with following name. `campaignanalytics-182101.Munidata.MuniHenUniAssocMstDtl` 



SELECT 
ConsolidatedAssocName,
case when concat( AssocAddress1,' ', AssocCity,' ', AssocState,' ', AssocZipCode ) is not null 
          then concat( AssocAddress1,' ', AssocCity,' ', AssocState,' ', AssocZipCode ) 
          else AssociationFullAddr 
          end AssocAddr,
ContactName,
ContactPhoneNumber,
ContactEmailID
AssocWebsite,        
AssocPhoneNumber 
FROM `campaignanalytics-182101.Munidata.MuniHenUniAssocMstDtl` 
order by 1 







/***************************************** 
Analyze data for Latrisha Vetaw for contributions data based on Barb Johnson filling 

*/

-- This query gives all the association donations that 

-- This query gives all the contributions that Barb has recived that are From Associations . This comes to 43 records, however there were couple of names that had duplicates
-- that were removed manually which were "Gray Plant Mooty Mooty and Bennett Independent PAC" and "Lockridge Grindal & Nauen State Political Fund". So the final record count is 41.
-- I also manually mapped these to the association data we have from PACs, Lobbying & google place API to get contact and other details. 
SELECT 
replace (ContributorName,',','') ContriName,
--Since the address variable causes duplicate records for contribution 
max(Concat(ContributorAddress, ' , ', (case when City = 'Mpls' then 'Minneapolis' else City end ), ' , ',State,' , ',ZipCode)) ContriFullAddr,
ContributorName,
`campaignanalytics-182101.dq.dq_B_ContriCategory`(ContributorsEmployer, ContributorName)  ContritutionCategory,
ContributorsEmployer, 
sum(ReceivedThisPeriod) TotalDonationRevceivedAmt,
sum(case when EXTRACT(year FROM    dateRecd) = 2014 then ReceivedThisPeriod end) TotContribution2014,
sum(case when EXTRACT(year FROM    dateRecd) = 2015 then ReceivedThisPeriod end) TotContribution2015,
sum(case when EXTRACT(year FROM    dateRecd) = 2016 then ReceivedThisPeriod end) TotContribution2016,
sum(case when EXTRACT(year FROM    dateRecd) = 2017 then ReceivedThisPeriod end) TotContribution2017
FROM
  `campaignanalytics-182101.Munidata.MuniHenContriData12312020` contri
JOIN (select candidatemst.* from 
`campaignanalytics-182101.Munidata.MuniHenCandMst` candidatemst join 
(select Candidate_name, max(Registration_date)  maxRegistrationDt
from   `campaignanalytics-182101.Munidata.MuniHenCandMst` group by  Candidate_name) candmax 
on candmax.Candidate_name = candidatemst.Candidate_name and maxRegistrationDt = candidatemst.Registration_date ) cand ON TRIM(contri.CandidateName) = TRIM(cand.Candidate_name)
JOIN (Select trim(CandidateName) CandName ,   ROUND(SUM(ReceivedThisPeriod),2) + ROUND(SUM(Coalesce(ValueofinKindDonation,0)),2) TotalDonation 
      from `campaignanalytics-182101.Munidata.MuniHenContriData12312020` 
      where EXTRACT(year FROM    dateRecd) in (2014,2015,2016,2017)
      Group by CandidateName) on TRIM(contri.CandidateName) = CandName 
where cand.Location = 'Minneapolis' and
trim(contri.candidatename) = 'Johnson, Barbara'
and `campaignanalytics-182101.dq.dq_B_ContriCategory`(Contri.ContributorsEmployer, Contri.ContributorName) = 'Association'
and EXTRACT(year FROM dateRecd) in (2014,2015,2016,2017)
group by 
ContriName,
ContributorName,
`campaignanalytics-182101.dq.dq_B_ContriCategory`(ContributorsEmployer, ContributorName) ,
 ContributorsEmployer
 order by 1



-- This query gives all the contributions by contribution category. I took the employer field from here and mapped to 
-- category of Lawyer, developer, businessOwner, Individuals, Asspcoation. Based on the mannual mapping i then updated the categorization function to reflect the category over there. 
SELECT 
contri.CandidateName, 
 `campaignanalytics-182101.dq.dq_B_ContriCategory`(Contri.ContributorsEmployer, Contri.ContributorName) ContributorCategory,
sum(ReceivedThisPeriod) TotalDonationRevceivedAmt,
round(sum(ReceivedThisPeriod)/avg(TotalDonation),2) PercentageTotalDonationRevceivedAmt,
sum(case when EXTRACT(year FROM    dateRecd) = 2014 then ReceivedThisPeriod end) TotContribution2014,
sum(case when EXTRACT(year FROM    dateRecd) = 2015 then ReceivedThisPeriod end) TotContribution2015,
sum(case when EXTRACT(year FROM    dateRecd) = 2016 then ReceivedThisPeriod end) TotContribution2016,
sum(case when EXTRACT(year FROM    dateRecd) = 2017 then ReceivedThisPeriod end) TotContribution2017,
round(sum(case when EXTRACT(year FROM    dateRecd) = 2017 then ReceivedThisPeriod end)/avg(Total2017Contribution),2) PercentageTotContribution2017
FROM
  `campaignanalytics-182101.Munidata.MuniHenContriData12312020` contri
JOIN 
--This query gets a unique record for a given candidate based on max registration date
(select candidatemst.* from 
        `campaignanalytics-182101.Munidata.MuniHenCandMst` candidatemst join 
         (select Candidate_name, max(Registration_date)  maxRegistrationDt
            from   `campaignanalytics-182101.Munidata.MuniHenCandMst` group by  Candidate_name) candmax 
          on candmax.Candidate_name = candidatemst.Candidate_name and maxRegistrationDt = candidatemst.Registration_date ) cand 
ON TRIM(contri.CandidateName) = TRIM(cand.Candidate_name)
--this query gievs the total donation for a given candidate so that you can calculate what percentage of donation comes from different donation category
JOIN (Select trim(CandidateName) CandName ,   ROUND(SUM(ReceivedThisPeriod),2) TotalDonation , sum(case when EXTRACT(year FROM    dateRecd) = 2017 then ReceivedThisPeriod end) Total2017Contribution
      from `campaignanalytics-182101.Munidata.MuniHenContriData12312020` 
      where EXTRACT(year FROM    dateRecd) in (2014,2015,2016,2017)
      Group by CandidateName) 
on TRIM(contri.CandidateName) = CandName 
where cand.Location = 'Minneapolis' and
trim(contri.candidatename) = 'Johnson, Barbara'
--and `campaignanalytics-182101.dq.dq_B_ContriCategory`(Contri.ContributorsEmployer, Contri.ContributorName) = 'Business'
and EXTRACT(year FROM dateRecd) in (2014,2015,2016,2017)
group by 
ContributorCategory,
CandidateName
 order by 1





/********** 
Analyze Different category of contributions  
************/ 

---Analyze data for specific  contribution category to understand the employer who are engaged in political contribution 
SELECT
contri.CandidateName,
`campaignanalytics-182101.dq.dq_B_ContriCategory`(Contri.ContributorsEmployer, Contri.ContributorName) ContributorCategory,
soundex(ContributorsEmployer) EmployerSoudex,
ContributorsEmployer ,
count(distinct contri.ContributorName) CountOfUniContributors,
sum(case when EXTRACT(year FROM dateRecd) = 2017 then ReceivedThisPeriod end) TotContribution2017,
sum(ReceivedThisPeriod) TotalDonationRevceivedAmt,
sum(case when EXTRACT(year FROM dateRecd) = 2014 then ReceivedThisPeriod end) TotContribution2014,
sum(case when EXTRACT(year FROM dateRecd) = 2015 then ReceivedThisPeriod end) TotContribution2015,
sum(case when EXTRACT(year FROM dateRecd) = 2016 then ReceivedThisPeriod end) TotContribution2016
FROM
`campaignanalytics-182101.Munidata.MuniHenContriData12312020` contri
JOIN
--This query gets a unique record for a given candidate based on max registration date
(select candidatemst.* from
`campaignanalytics-182101.Munidata.MuniHenCandMst` candidatemst join
(select Candidate_name, max(Registration_date) maxRegistrationDt
from `campaignanalytics-182101.Munidata.MuniHenCandMst` group by Candidate_name) candmax
on candmax.Candidate_name = candidatemst.Candidate_name and maxRegistrationDt = candidatemst.Registration_date ) cand
ON TRIM(contri.CandidateName) = TRIM(cand.Candidate_name)
--this query gievs the total donation for a given candidate so that you can calculate what percentage of donation comes from different donation category
JOIN (Select trim(CandidateName) CandName , ROUND(SUM(ReceivedThisPeriod),2) TotalDonation , sum(case when EXTRACT(year FROM dateRecd) = 2017 then ReceivedThisPeriod end) Total2017Contribution
from `campaignanalytics-182101.Munidata.MuniHenContriData12312020`
where EXTRACT(year FROM dateRecd) in (2014,2015,2016,2017)
Group by CandidateName)
on TRIM(contri.CandidateName) = CandName
where cand.Location = 'Minneapolis' and
trim(contri.candidatename) = 'Johnson, Barbara'
-- This function gives you different catribution categories to consider
and `campaignanalytics-182101.dq.dq_B_ContriCategory`(Contri.ContributorsEmployer, Contri.ContributorName) = 'Individual' --'BusinessOwner'
and EXTRACT(year FROM dateRecd) in (2014,2015,2016,2017)
group by
EmployerSoudex,
ContributorsEmployer,
CandidateName,
ContributorCategory
order by 6 desc



--- Analyze individual contributions that comes under a category 
SELECT
contri.CandidateName,
`campaignanalytics-182101.dq.dq_B_ContriCategory`(Contri.ContributorsEmployer, Contri.ContributorName) ContributorCategory,
Concat(ContributorAddress, ' ', (case when City = 'Mpls' then 'Minneapolis' else City end ), ' , ',State,' ',ZipCode) ContriFullAddr,
soundex(contri.ContributorName) EmployerSoudex,
max(contri.ContributorName) ContributorName,
max(ContributorsEmployer) ContributorsEmployer,
count(distinct contri.ContributorName) CountOfUniContributors,
sum(case when EXTRACT(year FROM dateRecd) = 2017 then ReceivedThisPeriod end) TotContribution2017,
sum(ReceivedThisPeriod) TotalDonationRevceivedAmt,
sum(case when EXTRACT(year FROM dateRecd) = 2014 then ReceivedThisPeriod end) TotContribution2014,
sum(case when EXTRACT(year FROM dateRecd) = 2015 then ReceivedThisPeriod end) TotContribution2015,
sum(case when EXTRACT(year FROM dateRecd) = 2016 then ReceivedThisPeriod end) TotContribution2016
FROM
`campaignanalytics-182101.Munidata.MuniHenContriData12312020` contri
JOIN
--This query gets a unique record for a given candidate based on max registration date
(select candidatemst.* from
`campaignanalytics-182101.Munidata.MuniHenCandMst` candidatemst join
(select Candidate_name, max(Registration_date) maxRegistrationDt
from `campaignanalytics-182101.Munidata.MuniHenCandMst` group by Candidate_name) candmax
on candmax.Candidate_name = candidatemst.Candidate_name and maxRegistrationDt = candidatemst.Registration_date ) cand
ON TRIM(contri.CandidateName) = TRIM(cand.Candidate_name)
--this query gievs the total donation for a given candidate so that you can calculate what percentage of donation comes from different donation category
JOIN (Select trim(CandidateName) CandName , ROUND(SUM(ReceivedThisPeriod),2) TotalDonation , sum(case when EXTRACT(year FROM dateRecd) = 2017 then ReceivedThisPeriod end) Total2017Contribution
from `campaignanalytics-182101.Munidata.MuniHenContriData12312020`
where EXTRACT(year FROM dateRecd) in (2014,2015,2016,2017)
Group by CandidateName)
on TRIM(contri.CandidateName) = CandName
where cand.Location = 'Minneapolis' and
trim(contri.candidatename) = 'Johnson, Barbara'
and `campaignanalytics-182101.dq.dq_B_ContriCategory`(Contri.ContributorsEmployer, Contri.ContributorName) = 'Individual' --'BusinessOwner'
and EXTRACT(year FROM dateRecd) in (2014,2015,2016,2017)
group by
ContriFullAddr,
EmployerSoudex,
CandidateName,
ContributorCategory
order by 6,8 desc









/* 
In order to get the contact details of the contritors such as email and phone, we would like to run this query that gives name,address & employer
*/

select 
trim(Upper(substr(FullName, 1 , instr(FullName,' ')-1))) Firstname,
trim(Upper(substr(FullName,instr(FullName,' ',-1)+1,length(FullName)))) Lastname,
substr(FullAddr,1,instr(FullAddr,'|')-1) address1,
trim(substr(FullAddr,instr(FullAddr,'|')+1,(instr(FullAddr,'|',1,2)-2)-instr(FullAddr,'|')+1)) City,
'MN' State,
trim(substr(FullAddr,instr(FullAddr,'|',-1)+1,length(FullAddr))) ZipCode,
Employer
from (
SELECT 
soundex(upper(replace (ContributorName,',',''))) soundexName,
`campaignanalytics-182101.dq.dq_B_ContriCategory`(Contri.ContributorsEmployer, Contri.ContributorName) ContriType,
max(upper(replace (ContributorName,',',''))) FullName,
--Since the address variable causes duplicate records for contribution 
max(Concat(ContributorAddress, ' | ', (case when City = 'Mpls' then 'Minneapolis' else City end ), ' | ',State,' | ',ZipCode)) FullAddr ,
max(ContributorsEmployer) Employer
FROM
  `campaignanalytics-182101.Munidata.MuniHenContriData12312020` contri
JOIN (select candidatemst.* from 
      `campaignanalytics-182101.Munidata.MuniHenCandMst` candidatemst join 
        (select Candidate_name, max(Registration_date)  maxRegistrationDt
          from   `campaignanalytics-182101.Munidata.MuniHenCandMst` group by  Candidate_name) candmax 
      on candmax.Candidate_name = candidatemst.Candidate_name and maxRegistrationDt = candidatemst.Registration_date ) cand 
ON TRIM(contri.CandidateName) = TRIM(cand.Candidate_name)
where cand.Location = 'Minneapolis' and
trim(contri.candidatename) = 'Johnson, Barbara'
and `campaignanalytics-182101.dq.dq_B_ContriCategory`(Contri.ContributorsEmployer, Contri.ContributorName) <> 'Association'
and EXTRACT(year FROM dateRecd) in (2014,2015,2016,2017) 
group by 
soundexName,
ContriType) 
order by 1,2,3






/*
Sample list of Contributor names that have run by datafinder application to get the contact details 
*/

SELECT 
Name,
`campaignanalytics-182101.dq.dq_B_ContriCategory`(null , upper(Name)) ContriCat,
Upper(trim(replace(substr(Name,1,instr(Name,' ')),',',''))) FirstName, 
Upper(trim(replace(substr(Name,instr(Name,' ')),',',''))) LastName, 
address1,
City,
State,
Zipcode  
FROM `campaignanalytics-182101.Munidata.MuniHenContriContactDetails` 
where `campaignanalytics-182101.dq.dq_B_ContriCategory`(null , upper(Name)) <> 'Association'






-- Steps we need to get the list of prospect for Latrisha to use 
-- Step1. Get the list of unique non association names that have contributed to bard johnson. Make sure we do not have that name already run by datafinder system 
--        By comparing to table `campaignanalytics-182101.Munidata.MuniHenContriContactDetails`
-- Step2. Once we have the subset of list then run it by datafinder to get email and phone numbers 
-- Once we have a list of address, email and phone you can expose that through the app which will be the version that i want to release for Latrisha to use. 



select 
trim(Upper(substr(FullName, 1 , if(instr(FullName,' ')<=0 , 0, instr(FullName,' ') -1)))) Firstname,
trim(Upper(substr(FullName,instr(FullName,' ',-1)+1,length(FullName)))) Lastname,
substr(FullAddr,1,if(instr(FullAddr,'|') <=0 , 0, instr(FullAddr,'|')-1)) address1,
trim(substr(FullAddr,instr(FullAddr,'|')+1,(if(instr(FullAddr,'|',1,2) <=2, 0, instr(FullAddr,'|',1,2)-2)-instr(FullAddr,'|')+1))) City,
'MN' State,
trim(substr(FullAddr,instr(FullAddr,'|',-1)+1,length(FullAddr))) ZipCode,
Employer
from (
SELECT 
soundex(upper(replace (ContributorName,',',''))) soundexName,
`campaignanalytics-182101.dq.dq_B_ContriCategory`(Contri.ContributorsEmployer, Contri.ContributorName) ContriType,
max(upper(replace (ContributorName,',',''))) FullName,
--Since the address variable causes duplicate records for contribution 
max(Concat(ContributorAddress, ' | ', (case when City = 'Mpls' then 'Minneapolis' else City end ), ' | ',State,' | ',ZipCode)) FullAddr ,
max(ContributorsEmployer) Employer
FROM
  `campaignanalytics-182101.Munidata.MuniHenContriData12312020` contri
JOIN (select candidatemst.* from 
      `campaignanalytics-182101.Munidata.MuniHenCandMst` candidatemst join 
        (select Candidate_name, max(Registration_date)  maxRegistrationDt
          from   `campaignanalytics-182101.Munidata.MuniHenCandMst` group by  Candidate_name) candmax 
      on candmax.Candidate_name = candidatemst.Candidate_name and maxRegistrationDt = candidatemst.Registration_date ) cand 
ON TRIM(contri.CandidateName) = TRIM(cand.Candidate_name)
WHERE cand.Location = 'Minneapolis' 
--and trim(contri.candidatename) = 'Johnson, Barbara'
and `campaignanalytics-182101.dq.dq_B_ContriCategory`(Contri.ContributorsEmployer, Contri.ContributorName) <> 'Association'
and EXTRACT(year FROM dateRecd) in (2014,2015,2016,2017) 
group by 
soundexName,
ContriType) Contribution 
LEFT OUTER JOIN (SELECT 
      Upper(trim(replace(substr(Name,1,instr(Name,' ')),',',''))) ContriFirstName, 
      Upper(trim(replace(substr(Name,instr(Name,' ')),',',''))) ContriLastName, 
      concat(Upper(trim(replace(substr(Name,1,instr(Name,' ')),',',''))), ' ' , Upper(trim(replace(substr(Name,instr(Name,' ')),',','')))) ContriFullName
      FROM `campaignanalytics-182101.Munidata.MuniHenContriContactDetails` 
      where `campaignanalytics-182101.dq.dq_B_ContriCategory`(null , upper(Name)) <> 'Association' ) ContriContact 
ON concat(trim(Upper(substr(FullName, 1 , if(instr(FullName,' ')<=0 , 0, instr(FullName,' ') -1)))) ,' ' ,trim(Upper(substr(FullName,instr(FullName,' ',-1)+1,length(FullName))))) =  ContriFullName
Where ContriFirstName is null
and trim(Upper(substr(FullName, 1 , if(instr(FullName,' ')<=0 , 0, instr(FullName,' ') -1)))) <> ''
order by 1,2,3



/* Create table  that has contributor details such as phone and email pulled from data provider such as 
data finder 
*/


create table `campaignanalytics-182101.Munidata.MuniHenContriContactDtlMst`
as (
SELECT 
Firstname,
Lastname,
MAX(CONCAT(ADDRESS1,' ' , CITY, ' ',state, ' ', zipcode)) fulladr, 
max(Employer) as employer,
max(phone) as phone,
max(phone_type) as phonetype,
max(Email_Address) as email,
max( Lifestyle_and_Interests) as Interests,
0 as givingScore,
0 as greenScore
FROM `campaignanalytics-182101.Munidata.MuniHenContriContactDetails02072021` 
WHERE (PHONE IS NOT NULL OR Email_Address IS NOT NULL OR CONCAT(ADDRESS1,' ' , CITY, ' ',state, ' ', zipcode) is not null)
group by Firstname,
Lastname
union Distinct 
SELECT 
Upper(trim(replace(substr(Name,1,instr(Name,' ')),',',''))) FirstName, 
Upper(trim(replace(substr(Name,instr(Name,' ')),',',''))) LastName, 
MAX(CONCAT(ADDRESS1,' ' , CITY, ' ',state, ' ', zipcode)) fulladr, 
'' employer,
max( Phone) as phone,
max( Phone_Type) as phoneType,
max( Email_Address) as email,
max( Lifestyle_and_Interests) as Interests,
max( Giving_Score) as givingScore,
max( Green_Score) as greenScore
FROM `campaignanalytics-182101.Munidata.MuniHenContriContactDetails` 
where `campaignanalytics-182101.dq.dq_B_ContriCategory`(null , upper(Name)) <> 'Association'
group by Upper(trim(replace(substr(Name,1,instr(Name,' ')),',',''))) , 
Upper(trim(replace(substr(Name,instr(Name,' ')),',',''))) 
)







/******************************
Data extract with the enriched email and phone number information along with the category of contributed that will beused for the app. 
*******************************/ 

select Distinct
INITCAP(FullName) as FullName,
trim(INITCAP(substr(FullName, 1 , if(instr(FullName,' ')<=0 , 0, instr(FullName,' ') -1)))) Firstname,
trim(INITCAP(substr(FullName,instr(FullName,' ',-1)+1,length(FullName)))) Lastname,
--substr(FullAddr,1,if(instr(FullAddr,'|') <=0 , 0, instr(FullAddr,'|')-1)) address1,
--trim(substr(FullAddr,instr(FullAddr,'|')+1,(if(instr(FullAddr,'|',1,2) <=2, 0, instr(FullAddr,'|',1,2)-2)-instr(FullAddr,'|')+1))) City,
--'MN' State,
--trim(substr(FullAddr,instr(FullAddr,'|',-1)+1,length(FullAddr))) ZipCode,
regexp_replace(FullAddr,'[^a-z0-9A-Z ]','') FullAddress,
--voter.VoterFullAddress,
Employer,
ContriType,
TotalDonationRevceivedAmt,
CountOfUniContributors,
-- Pick phone number from voter list or from the external data provider
case when voter.VoterPhone is not null then voter.VoterPhone else ContriContact.phone end PhoneNumber ,
ContriContact.email ,
ContriContact.interests,
ContriContact.givingscore
from 
-- This section of sub select gets a unique record for a contributor based on soundex name match to avoid any duplicates with contributor names
      (
      SELECT 
      soundex(upper(replace (ContributorName,',',''))) soundexName,
      `campaignanalytics-182101.dq.dq_B_ContriCategory`(Contri.ContributorsEmployer, Contri.ContributorName) ContriType,
      max(upper(replace (ContributorName,',',''))) FullName,
      --Since the address variable causes duplicate records for contribution 
      max(Concat(ContributorAddress, ' | ', (case when City = 'Mpls' then 'Minneapolis' else City end ), ' | ',State,' | ',ZipCode)) FullAddr ,
      max(ContributorsEmployer) Employer,
      count(distinct contri.ContributorName) CountOfUniContributors,
      sum(ReceivedThisPeriod) TotalDonationRevceivedAmt,
      sum(case when EXTRACT(year FROM dateRecd) = 2017 then ReceivedThisPeriod end) TotContribution2017,
      sum(case when EXTRACT(year FROM dateRecd) = 2014 then ReceivedThisPeriod end) TotContribution2014,
      sum(case when EXTRACT(year FROM dateRecd) = 2015 then ReceivedThisPeriod end) TotContribution2015,
      sum(case when EXTRACT(year FROM dateRecd) = 2016 then ReceivedThisPeriod end) TotContribution2016
      FROM
        `campaignanalytics-182101.Munidata.MuniHenContriData12312020` contri
      JOIN (select candidatemst.* from 
            `campaignanalytics-182101.Munidata.MuniHenCandMst` candidatemst join 
              (select Candidate_name, max(Registration_date)  maxRegistrationDt
                from   `campaignanalytics-182101.Munidata.MuniHenCandMst` group by  Candidate_name) candmax 
            on candmax.Candidate_name = candidatemst.Candidate_name and maxRegistrationDt = candidatemst.Registration_date ) cand 
      ON TRIM(contri.CandidateName) = TRIM(cand.Candidate_name)
      WHERE cand.Location = 'Minneapolis' 
      and trim(contri.candidatename) = 'Johnson, Barbara'
      and `campaignanalytics-182101.dq.dq_B_ContriCategory`(Contri.ContributorsEmployer, Contri.ContributorName) <> 'Association'
      and EXTRACT(year FROM dateRecd) in (2014,2015,2016,2017) 
      --and ContributorName like 'Ezell%'
      group by 
      soundexName,
      ContriType) Contribution 
-- This section of sub select has data that we bought from external provide for a given name & address. There are duplicates here again which needs to handled 
LEFT OUTER JOIN (SELECT   
                  Firstname,
                  Lastname,
                  max(phone) phone,
                  max(email)email,
                  max(interests) as interests,
                  max(givingScore) as givingscore, 
                  FROM `campaignanalytics-182101.Munidata.MuniHenContriContactDtlMst` 
                  where (phone is not null or email is not null)
                  group by 1,2) ContriContact 
ON (trim(Upper(substr(FullName, 1 , if(instr(FullName,' ')<=0 , 0, instr(FullName,' ') -1)))) = ContriContact.Firstname and 
    trim(Upper(substr(FullName,instr(FullName,' ',-1)+1,length(FullName)))) = ContriContact.Lastname)
-- This section of sub select makes a lookup to existing donors for a given candidate, so that we are not listing them out in the prospect list. This data is something that we need to get from the candidate 
LEFT OUTER JOIN ( SELECT distinct  TRIM(UPPER(SUBSTR(NAME,1,INSTR(NAME,' ')))) DonorFname,
                  TRIM(UPPER(SUBSTR(NAME,INSTR(NAME,' ')))) DonorLname 
                  FROM `campaignanalytics-182101.Munidata.LVDonorTxn` ) DonorNames
ON (trim(Upper(substr(FullName, 1 , if(instr(FullName,' ')<=0 , 0, instr(FullName,' ') -1)))) = DonorNames.DonorFname and 
    trim(Upper(substr(FullName,instr(FullName,' ',-1)+1,length(FullName)))) = DonorNames.DonorLname)
-- This section of sub select has data from SOS voter file that has list of all voters that are registed to vote in MN. We are pulling this in to get the phone numbers. 
LEFT OUTER JOIN (SELECT 
                FirstName as VoterFirstName,
                LastName as VoterLastName,
                City as VoterCity,
                ZipCode as VoterZipcode,
                HouseNumber as VoterHousenumber,
                Age as VoterAge,
                Generation as VoterGeneration,
                concat(HouseNumber,' ',StreetName,' ',UnitType, ' ',UnitNumber,' , ',Address2,' ',City, ' , ', State, ' ',ZipCode) as VoterFullAddress,
                PhoneNumber as VoterPhone
                FROM `campaignanalytics-182101.campaign.MN_VOTERS_ELECTION_ByYr_WAttrib_01172021` 
                ) voter
ON (trim(Upper(substr(FullName, 1 , if(instr(FullName,' ')<=0 , 0, instr(FullName,' ') -1)))) = voter.VoterFirstName and 
    trim(Upper(substr(FullName,instr(FullName,' ',-1)+1,length(FullName)))) = voter.VoterLastName and 
    Upper(trim(substr(FullAddr,instr(FullAddr,'|')+1,(if(instr(FullAddr,'|',1,2) <=2, 0, instr(FullAddr,'|',1,2)-2)-instr(FullAddr,'|')+1)))) = voter.votercity and
    trim(substr(FullAddr,instr(FullAddr,'|',-1)+1,length(FullAddr))) = voter.VoterZipcode and
    trim(substr(FullAddr,1,instr(FullAddr,' '))) = voter.VoterHousenumber
    )
Where DonorNames.DonorLname is null and 
 trim(Upper(substr(FullName, 1 , if(instr(FullName,' ')<=0 , 0, instr(FullName,' ') -1)))) <> ''
 --and ContriType = 'Lawyer'
 and Employer is not null
 --and (ContriContact.phone is null and voter.VoterPhone is not null)
order by Employer,FullName,TotalDonationRevceivedAmt



/* Comments from chakra on cleaning records manually 
Chakra Sankaraiah
Chakra Sankaraiah6:57 AM Today
SELECTED TEXT:
Robert Pohlad
Moved this record from bottom to the top to show along with other Kelber Catering records
Reply•Resolve
Chakra Sankaraiah
Chakra Sankaraiah6:55 AM Today
SELECTED TEXT:
David And Sandra Kvamme
Removed other record that had David Arid Sandra Kvamme
Reply•Resolve
Chakra Sankaraiah
Chakra Sankaraiah6:54 AM Today
SELECTED TEXT:
Eric Gaiatz And Lisa Piegel
Reflect right names for Eric and Gaiatz as two separate records Eric Gaiatz And Lisa Piegel
Reply•Resolve
Chakra Sankaraiah
Chakra Sankaraiah6:52 AM Today
SELECTED TEXT:
Hoyt Hsiao And Zhen Zhen Luo
Updated last name of Hoyt to show Hsiao instead of Luo
Reply•Resolve
Chakra Sankaraiah
Chakra Sankaraiah6:51 AM Today
SELECTED TEXT:
Bill Mcguire
Update this and next record to reflect the right name from Biii And Nadine to two separate names Bill and Nadine
Reply•Resolve
Chakra Sankaraiah
Chakra Sankaraiah6:43 AM Today
SELECTED TEXT:
Al Hofstede
Deleted other record that had Ai Hofstede
Reply•Resolve
Chakra Sankaraiah
Chakra Sankaraiah6:42 AM Today
SELECTED TEXT:
Charlie Hall
Deleted other record that has Charlie Halt as fullname
Reply•Resolve
Chakra Sankaraiah
Chakra Sankaraiah6:41 AM Today
SELECTED TEXT:
Fabian Hoffner
Manually deleted other record with name Fabian Hoffher

*/ 








/* 
Contributions received by LV via website contribution page
*/
SELECT 
NAME as FullName,
TRIM(UPPER(SUBSTR(NAME,1,INSTR(NAME,' ')))) FIRTNAME,
TRIM(UPPER(SUBSTR(NAME,INSTR(NAME,' ')))) LASTNAME,
CONCAT(ADDRESS1, ' ',CITY,' ',State_Province ,' ', ZIP) FULLADDR,
MAX(EMAIL) as Email,
MAX(PHONE) as Phone,
600 - sum(if(extract(year from created_at) = 21 , AMOUNT, 0)) PotentialContri2021,
sum(if(extract(year from created_at) = 21 , AMOUNT, 0)) TotalContributed2021,
sum(if(extract(year from created_at) = 20 , AMOUNT, 0)) TotalContributed2020 
FROM `campaignanalytics-182101.Munidata.LVDonorTxn`
--where extract(year from created_at) = 21
GROUP BY 
NAME,
TRIM(UPPER(SUBSTR(NAME,1,INSTR(NAME,' ')))) ,
TRIM(UPPER(SUBSTR(NAME,INSTR(NAME,' ')))) ,
CONCAT(ADDRESS1, ' ',CITY,' ',State_Province ,' ', ZIP) 



SELECT distinct 
TRIM(UPPER(SUBSTR(NAME,1,INSTR(NAME,' ')))) DonorFname,
TRIM(UPPER(SUBSTR(NAME,INSTR(NAME,' ')))) DonorLname 
FROM `campaignanalytics-182101.Munidata.LVDonorTxn`





-- Query to get all the attributes of potential contributors 

SELECT  
trim(replace(replace(ContriAmt.contributorName,",",""),".","")) FullName ,
Email_Address as EmailID,
phone as PrimaryNumber,
ContriAddr.FormattedFullAddress as FullAddress,
ContriBus.Name employer,
Contribus.Website BusinessWebsite,
Contribus.FormattedFullAddress BusinessAddress,
sum(ReceivedThisPeriod) PotentialDonationAmt 
FROM `campaignanalytics-182101.Munidata.MuniHenContriContactDetails` ContriContact 
join `campaignanalytics-182101.Munidata.MuniHenContriBusinessOwnerAddrDtl` ContriAddr on trim(replace(replace(ContriContact.Name,",",""),".","")) = trim(replace(replace(ContriAddr.contributorName,",",""),".",""))
join `campaignanalytics-182101.Munidata.MuniHenContriData` ContriAmt on trim(replace(replace(ContriAmt.contributorName,",",""),".","")) = trim(replace(replace(ContriContact.Name,",",""),".",""))
join `campaignanalytics-182101.Munidata.MuniHenContriBusinessDtls` ContriBus on ContriBus.EmployerName = ContriAmt.ContributorsEmployer
where contriContact.Phone is not null
and Email_Address is not null 
group by 
ContriAmt.contributorName  ,
Email_Address ,
phone ,
ContriAddr.FormattedFullAddress ,
ContriBus.Name ,
Contribus.Website ,
Contribus.FormattedFullAddress 
order by 8 desc





/* Contribution analysis for Lisa Bender donors 
*/ 

SELECT distinct 
`campaignanalytics-182101.dq.dq_B_ContriCategory`(Contri.ContributorsEmployer, Contri.ContributorName) ContributorCategory,
contri.ContributorName,
contri.ContributorsEmployer,
sum(contri.ReceivedThisPeriod) TotalContriThisPeriod,
sum(TotalFromSourceYeartoDate) TotalContriFromSrc
FROM
`campaignanalytics-182101.Munidata.MuniHenContriData04112021` contri
JOIN
--This query gets a unique record for a given candidate based on max registration date
(select candidatemst.* from
`campaignanalytics-182101.Munidata.MuniHenCandMst` candidatemst join
(select Candidate_name, max(Registration_date) maxRegistrationDt
from `campaignanalytics-182101.Munidata.MuniHenCandMst` group by Candidate_name) candmax
on candmax.Candidate_name = candidatemst.Candidate_name and maxRegistrationDt = candidatemst.Registration_date ) cand
ON TRIM(contri.CandidateName) = TRIM(cand.Candidate_name)
where cand.Location = 'Minneapolis' and
trim(contri.candidatename) = 'Bender, Lisa'
-- This function gives you different catribution categories to consider
--and `campaignanalytics-182101.dq.dq_B_ContriCategory`(Contri.ContributorsEmployer, Contri.ContributorName) = 'Others' --'BusinessOwner'
and EXTRACT(year FROM dateRecd) in (2014,2015,2016,2017)
group by 1,2,3
order by 2 ,3


/* 
This query analyze the o