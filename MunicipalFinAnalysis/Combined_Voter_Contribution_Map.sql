-- Combined query that maps all contributors to voters and aggregates by VoterID
-- Includes data from Jacob Frey donations, post-2021 campaign finance, and pre-2021 campaign finance
-- Returns one record per VoterID with aggregated contribution data

WITH JacobFreyDonors AS (
  -- Donors for Jacob Frey that can be mapped to voters in Minneapolis
  SELECT 
    V.VoterId,
    V.FirstName,
    V.MiddleName,
    V.LastName,
    V.FullAddress,
    V.ZipCode,
    'JACOB_FREY' AS source_type,
    'MODERATE' AS voter_category,
    COALESCE(MIN(t.Employer), 'Unknown') AS employer,
    SUM(t.Amount) AS total_contribution_amt,
    COUNT(*) AS contribution_count,
    MIN(t.Date) AS earliest_contribution_date,
    MAX(t.Date) AS latest_contribution_date
  FROM `campaignanalytics-182101.MNHenMplsMayorJacobF.JFMplsMayorDonationAll_Process` t 
  JOIN `campaignanalytics-182101.Data_Enrichment.MN_VOTERS_SEGMENTS_MPLS` V ON 
    ((CASE
        WHEN STRPOS(t.Name, ' ') > 0 THEN TRIM(SUBSTR(t.Name, 1, STRPOS(t.Name, ' ') - 1))
        ELSE t.Name
    END) = V.FirstName 
    AND (CASE
        WHEN STRPOS(t.Name, ' ') > 0 THEN TRIM(SUBSTR(t.Name, STRPOS(t.Name, ' ') + 1))
        ELSE NULL
    END) = V.LastName
    AND substring(TRIM(REGEXP_EXTRACT(FulladdressFormatted, r'.*?\|\|\s*(.*?)\s*\|\|\|.*?')),1,5) = V.zipcode)
  WHERE FulladdressFormatted LIKE '%MINNEAPOLIS%'
    AND FulladdressFormatted LIKE '%|%||%|||%'
    AND (1 - (EDIT_DISTANCE(V.FullAddress, t.FulladdressFormatted) / CAST(GREATEST(LENGTH(V.FullAddress), LENGTH(t.FulladdressFormatted)) AS FLOAT64))) >= 0.5
  GROUP BY 1,2,3,4,5,6,7
),

Post2021Donors AS (
  -- Minneapolis Donors post 2021 mapped to voters based on campaign finance data 
  SELECT  
    V.VoterId,
    V.FirstName,
    CAST(NULL AS STRING) AS MiddleName,
    V.LastName,
    V.FullAddress,
    V.zipcode AS ZipCode,
    'POST_2021' AS source_type,
    MIN(CASE 
      WHEN REGEXP_CONTAINS(UPPER(Recipient_Campaign), r'FREY|RAINVILLE|ANDREA|VETAW|CASHMAN') THEN 'MODERATE' 
      WHEN REGEXP_CONTAINS(UPPER(Recipient_Campaign), r'FATEH|CHUGHTAI|SOREN|ROBIN|CHAVEZ') THEN 'SOCIALIST'
      ELSE 'UNKNOWN' 
    END) AS voter_category,
    COALESCE(MIN(C.Employer), 'Unknown') AS employer,
    CAST(SUM(Amount) AS INT64) AS total_contribution_amt,
    COUNT(*) AS contribution_count,
    MIN(CAST(Contribution_Date  AS DATE)) AS earliest_contribution_date,
    MAX(CAST(Contribution_Date  AS DATE)) AS latest_contribution_date
  FROM `campaignanalytics-182101.Munidata.Mpls_CampaignFinance_082025` C 
  JOIN `campaignanalytics-182101.Data_Enrichment.MN_VOTERS_SEGMENTS_MPLS` V ON 
    (UPPER(C.Contributor_First_Name) = V.FirstName 
     AND UPPER(C.Contributor_LAST_Name) = V.LastName 
     AND CAST(C.Zip_Code AS STRING) = V.zipcode)
  WHERE (1 - (EDIT_DISTANCE(V.FullAddress, UPPER(CONCAT(`Street_Address 1`," ",Contributor_City," ", Contributor_State, " " ,Zip_Code))) / CAST(GREATEST(LENGTH(V.FullAddress), LENGTH(UPPER(CONCAT(`Street_Address 1`," ",Contributor_City," ", Contributor_State, " " ,Zip_Code)))) AS FLOAT64))) >= 0.4
    AND UPPER(TRIM(Contributor_City)) IN ('MINNEAPOLIS','MPLS')
  GROUP BY 1,2,3,4,5,6
),

Pre2021Donors AS (
  -- Minneapolis donors pre 2021 mapped to voters based on campaign finance data
  SELECT 
    V.VoterId,
    V.FirstName,
    CAST(NULL AS STRING) AS MiddleName,
    V.LastName,
    V.FullAddress,
    V.ZipCode,
    'PRE_2021' AS source_type,
    CASE 
      WHEN REGEXP_CONTAINS(UPPER(CO.Candidatename), r'TOM|HODGES|STEVEN|REICH|RAINVILLE|ANDREA|VETAW|CASHMAN') THEN 'MODERATE' 
      WHEN REGEXP_CONTAINS(UPPER(CO.Candidatename), r'SHEILA|NELSON|ROBIN|CHAVEZ|CHUGHTAI|ROSENFELD') THEN 'SOCIALIST'
      ELSE 'UNKNOWN' 
    END AS voter_category,
    COALESCE(MIN(CO.ContributorsEmployer), 'Unknown') AS employer,
    SUM(IFNULL(TotalFromSourceYeartoDate, ValueofinKindDonation)) AS total_contribution_amt,
    COUNT(*) AS contribution_count,
    MIN(CAST(DateRecd AS DATE)) AS earliest_contribution_date,
    MAX(CAST(DateRecd AS DATE)) AS latest_contribution_date
  FROM Munidata.MuniHenContriData04112021 CO  
  JOIN Munidata.MuniHenCandMst07222021 cand ON CO.CandidateName = cand.Candidate_name 
  JOIN `campaignanalytics-182101.Data_Enrichment.MN_VOTERS_SEGMENTS_MPLS` V ON 
    (UPPER((CASE
        WHEN STRPOS(CO.ContributorName, ' ') > 0 THEN TRIM(SUBSTR(CO.ContributorName, 1, STRPOS(CO.ContributorName, ' ') - 1))
        ELSE CO.ContributorName
    END)) = V.FirstName 
    AND UPPER((CASE
        WHEN STRPOS(CO.ContributorName, ' ') > 0 THEN TRIM(SUBSTR(CO.ContributorName, STRPOS(CO.ContributorName, ' ') + 1))
        ELSE NULL
    END)) = V.LastName 
    AND (CASE 
        WHEN CO.ZipCode IS NULL THEN TRUE 
        ELSE SUBSTRING(CO.ZipCode,1,5) = V.ZipCode 
    END))
  WHERE CO.CandidateName NOT LIKE '%Frey%'
    AND UPPER(CO.City) = 'MINNEAPOLIS'
    AND (1 - (EDIT_DISTANCE(V.FullAddress, UPPER(CONCAT(CO.ContributorAddress," ",CO.City," ", CO.State, " " ,IFNULL(CO.ZipCode,'')))) / CAST(GREATEST(LENGTH(V.FullAddress), LENGTH(UPPER(CONCAT(CO.ContributorAddress," ",CO.City," ", CO.State, " " ,IFNULL(CO.ZipCode,''))))) AS FLOAT64))) >= 0.7
  GROUP BY 1,2,3,4,5,6,7,8
),

CombinedData AS (
  SELECT * FROM JacobFreyDonors
  UNION ALL
  SELECT * FROM Post2021Donors  
  UNION ALL
  SELECT * FROM Pre2021Donors
)

-- Final aggregation: one record per VoterID with all contribution data combined
SELECT 
  VoterId,
  ANY_VALUE(FirstName) AS FirstName,
  ANY_VALUE(MiddleName) AS MiddleName,
  ANY_VALUE(LastName) AS LastName,
  ANY_VALUE(FullAddress) AS FullAddress,
  ANY_VALUE(ZipCode) AS ZipCode,
  STRING_AGG(DISTINCT employer ORDER BY employer) AS employers,
  
  -- Aggregate contribution data across all sources
  SUM(total_contribution_amt) AS total_contribution_amt_all_sources,
  SUM(contribution_count) AS total_contribution_count_all_sources,
  MIN(earliest_contribution_date) AS earliest_contribution_date_overall,
  MAX(latest_contribution_date) AS latest_contribution_date_overall,
  
  -- Source breakdown
  STRING_AGG(DISTINCT source_type ORDER BY source_type) AS contribution_sources,
  
  -- Voter category (prioritize MODERATE > SOCIALIST > UNKNOWN)
  CASE 
    WHEN 'MODERATE' IN UNNEST(ARRAY_AGG(DISTINCT voter_category)) THEN 'MODERATE'
    WHEN 'SOCIALIST' IN UNNEST(ARRAY_AGG(DISTINCT voter_category)) THEN 'SOCIALIST'
    ELSE 'UNKNOWN'
  END AS final_voter_category,
  
  -- Detailed breakdown by source
  SUM(CASE WHEN source_type = 'JACOB_FREY' THEN total_contribution_amt ELSE 0 END) AS jacob_frey_contribution_amt,
  SUM(CASE WHEN source_type = 'JACOB_FREY' THEN contribution_count ELSE 0 END) AS jacob_frey_contribution_count,
  
  -- Combined all campaign finance contributions (POST_2021 + PRE_2021)
  SUM(CASE WHEN source_type IN ('POST_2021', 'PRE_2021') THEN total_contribution_amt ELSE 0 END) AS campaign_finance_contribution_amt,
  SUM(CASE WHEN source_type IN ('POST_2021', 'PRE_2021') THEN contribution_count ELSE 0 END) AS campaign_finance_contribution_count,
  
  -- Flags
  CASE WHEN SUM(CASE WHEN source_type = 'JACOB_FREY' THEN 1 ELSE 0 END) > 0 THEN 'Y' ELSE 'N' END AS jacob_frey_donor_flag,
  CASE WHEN SUM(CASE WHEN source_type IN ('POST_2021', 'PRE_2021') THEN 1 ELSE 0 END) > 0 THEN 'Y' ELSE 'N' END AS campaign_finance_donor_flag

FROM CombinedData
GROUP BY VoterId
ORDER BY total_contribution_amt_all_sources DESC;

-- To create the table in BigQuery, run the following command:
-- bq query --use_legacy_sql=false --destination_table=campaignanalytics-182101:Munidata.Mpls_Voter_Contribution_Map_2025 --replace --format=pretty < Combined_Voter_Contribution_Map.sql

-- Table created: campaignanalytics-182101.Munidata.Mpls_Voter_Contribution_Map_2025
-- Contains one record per VoterID with aggregated contribution data from all sources
