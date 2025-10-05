-- This file maps a contriobutor to a voter if possible using name and address matching


-- Donors for Jacob Frey that can be mapped to voters in Minneapolis
select distinct 
VoterId,
V.FirstName,
V.MiddleName,
V.LastName,
V.FullAddress,
COALESCE(t.Employer, 'Unknown') AS Employer,
sum(t.Amount) ContriAmt 
from `campaignanalytics-182101.MNHenMplsMayorJacobF.JFMplsMayorDonationAll_Process` t 
join  `campaignanalytics-182101.Data_Enrichment.MN_VOTERS_SEGMENTS_MPLS` V on 
((CASE
    WHEN STRPOS(t.Name, ' ') > 0 THEN TRIM(SUBSTR(t.Name, 1, STRPOS(t.Name, ' ') - 1))
    ELSE t.Name
END) = V.FirstName and (CASE
    WHEN STRPOS(t.Name, ' ') > 0 THEN TRIM(SUBSTR(t.Name, STRPOS(t.Name, ' ') + 1))
    ELSE NULL
END) = V.LastName
AND 
substring(TRIM(REGEXP_EXTRACT(FulladdressFormatted, r'.*?\|\|\s*(.*?)\s*\|\|\|.*?')),1,5) = v.zipcode
)
where FulladdressFormatted like '%MINNEAPOLIS%'
AND FulladdressFormatted LIKE '%|%||%|||%'
and (1 - (EDIT_DISTANCE(V.FullAddress, t.FulladdressFormatted) / CAST(GREATEST(LENGTH(V.FullAddress), LENGTH(t.FulladdressFormatted)) AS FLOAT64))) >= 0.5
group by 1,2,3,4,5,6
order by 7 desc;


-- Minneapolis Donors post 2021 mapped to voters based on camapaign finance data 

select  
V.VoterId,
V.FirstName,
V.LastName,
v.zipcode,
V.FullAddress,
COALESCE(C.Employer, 'Unknown') AS Employer,
--Upper( CONCAT(`Street_Address 1`," ",Contributor_City," ", Contributor_State, " " ,Zip_Code))  as FullAddress, 
MIN((Case when REGEXP_CONTAINS(upper(Recipient_Campaign), r'FREY|RAINVILLE|ANDREA|VETAW|CASHMAN') then 'MODERATE' 
when REGEXP_CONTAINS(upper(Recipient_Campaign), r'FATEH|CHUGHTAI|SOREN|ROBIN|CHAVEZ') then 'SOCIALIST'
else 'UNKNOWN' 
end) ) VoterCategory, 
'Y' DonorFlag,
cast (sum(Amount) as INT64) as ContriAmt,
Count (*) ContriCount
from `campaignanalytics-182101.Munidata.Mpls_CampaignFinance_082025` C 
join  `campaignanalytics-182101.Data_Enrichment.MN_VOTERS_SEGMENTS_MPLS` V on 
( Upper(C.Contributor_First_Name)= V.FirstName and 
Upper(C.Contributor_LAST_Name) = V.LastName AND 
cast ( C.Zip_Code as STRING) = v.zipcode )
where 
(1 - (EDIT_DISTANCE(V.FullAddress, Upper( CONCAT(`Street_Address 1`," ",Contributor_City," ", Contributor_State, " " ,Zip_Code))) / CAST(GREATEST(LENGTH(V.FullAddress), LENGTH(Upper( CONCAT(`Street_Address 1`," ",Contributor_City," ", Contributor_State, " " ,Zip_Code)))) AS FLOAT64))) >= 0.4
and upper(trim(Contributor_City)) in ('MINNEAPOLIS','MPLS')
group by 1 ,2,3,4,5,6
order by 9 desc



-- Minneapolis donors pre 2021 mapped to voters based on camapaign finance data
select 
V.VoterId,
CO.ContributorName,
Upper((CASE
    WHEN STRPOS(CO.ContributorName, ' ') > 0 THEN TRIM(SUBSTR(CO.ContributorName, 1, STRPOS(CO.ContributorName, ' ') - 1))
    ELSE CO.ContributorName
END)) as FirstName,
V.FirstName,
Upper((CASE
    WHEN STRPOS(CO.ContributorName, ' ') > 0 THEN TRIM(SUBSTR(CO.ContributorName, STRPOS(CO.ContributorName, ' ') + 1))
    ELSE NULL
END )) as LastName,
V.Lastname,
V.FullAddress,
COALESCE(CO.ContributorsEmployer, 'Unknown') AS Employer,
Upper( CONCAT(CO.ContributorAddress," ",CO.City," ", CO.State, " " ,IFNULL(CO.ZipCode,''))) C_FullAddress, 
(1 - (EDIT_DISTANCE(V.FullAddress, Upper( CONCAT(CO.ContributorAddress," ",CO.City," ", CO.State, " " ,IFNULL(CO.ZipCode,'')))) / CAST(GREATEST(LENGTH(V.FullAddress), LENGTH(Upper( CONCAT(CO.ContributorAddress," ",CO.City," ", CO.State, " " ,IFNULL(CO.ZipCode,''))))) AS FLOAT64))) LDist,
Upper(CO.ContributorAddress) Address1,
Upper(CO.City) as City,
Upper(CO.State) as State,
substring(CO.ZipCode,1,5) ZipCode,
Upper( CONCAT(CO.ContributorAddress," ",CO.City," ", CO.State, " " ,IFNULL(CO.ZipCode,''))) FullAddress, 
DateRecd, 
CO.Candidatename,
CO.ContributorsEmployer,
cand.Committee_name,
cand.Office,
(Case when REGEXP_CONTAINS(upper(CO.Candidatename), r'TOM|HODGES|STEVEN|REICH|RAINVILLE|ANDREA|VETAW|CASHMAN') then 'MODERATE' 
when REGEXP_CONTAINS(upper(CO.Candidatename), r'SHEILA|NELSON|ROBIN|CHAVEZ|CHUGHTAI|ROSENFELD') then 'SOCIALIST'
else 'UNKNOWN' 
end)  VoterCategory, 
IFNULL(TotalFromSourceYeartoDate,ValueofinKindDonation) ContriAmt
from 
Munidata.MuniHenContriData04112021 CO  
join Munidata.MuniHenCandMst07222021 cand on CO.CandidateName = cand.Candidate_name 
Join `campaignanalytics-182101.Data_Enrichment.MN_VOTERS_SEGMENTS_MPLS` V on 
(Upper((CASE
    WHEN STRPOS(CO.ContributorName, ' ') > 0 THEN TRIM(SUBSTR(CO.ContributorName, 1, STRPOS(CO.ContributorName, ' ') - 1))
    ELSE CO.ContributorName
END))) = V.FirstName 
and 
Upper((CASE
    WHEN STRPOS(CO.ContributorName, ' ') > 0 THEN TRIM(SUBSTR(CO.ContributorName, STRPOS(CO.ContributorName, ' ') + 1))
    ELSE NULL
END )) = V.LastName 
and 
(Case when CO.ZipCode IS NULL then 1=1 else 
 substring(CO.ZipCode,1,5)= V.ZipCode 
 end )
where CandidateName not like '%Frey%'
and Upper(CO.City) = 'MINNEAPOLIS'
 and (1 - (EDIT_DISTANCE(V.FullAddress, Upper( CONCAT(CO.ContributorAddress," ",CO.City," ", CO.State, " " ,IFNULL(CO.ZipCode,'')))) / CAST(GREATEST(LENGTH(V.FullAddress), LENGTH(Upper( CONCAT(CO.ContributorAddress," ",CO.City," ", CO.State, " " ,IFNULL(CO.ZipCode,''))))) AS FLOAT64))) >= 0.7

