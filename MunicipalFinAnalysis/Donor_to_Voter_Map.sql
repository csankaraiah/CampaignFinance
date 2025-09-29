-- This file maps a contriobutor to a voter if possible using name and address matching


-- Donors for Jacob Frey that can be mapped to voters in Minneapolis
select distinct 
V.FirstName,
V.LastName,
Name,
  CASE
    WHEN STRPOS(t.Name, ' ') > 0 THEN TRIM(SUBSTR(t.Name, 1, STRPOS(t.Name, ' ') - 1))
    ELSE t.Name
END
  AS FirstName,
  CASE
    WHEN STRPOS(t.Name, ' ') > 0 THEN TRIM(SUBSTR(t.Name, STRPOS(t.Name, ' ') + 1))
    ELSE NULL
END
  AS LastName,
FulladdressFormatted,
  TRIM(REGEXP_EXTRACT(FulladdressFormatted, r'^(.*?)\s*\|\s*.*?')) AS Address1,
  TRIM(REGEXP_EXTRACT(FulladdressFormatted, r'.*?\|\s*(.*?)\s*\|\|.*?')) AS City,
  TRIM(REGEXP_EXTRACT(FulladdressFormatted, r'.*?\|\|\s*(.*?)\s*\|\|\|.*?')) AS Zip,
  TRIM(REGEXP_EXTRACT(FulladdressFormatted, r'.*?\|\|\|\s*(.*)$')) AS State 
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
AND FulladdressFormatted LIKE '%|%||%|||%';