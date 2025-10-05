-- Combined view that unifies all three contribution data sources
-- Aligns columns and data types across Jacob Frey donations, post-2021 campaign finance, and pre-2021 campaign finance
-- Returns all individual transactions from each table with standardized schema

CREATE OR REPLACE VIEW `campaignanalytics-182101.Munidata.Mpls_All_Contributions_View` AS

WITH JacobFreyContributions AS (
  -- Jacob Frey donation transactions
  SELECT 
    CAST('JACOB_FREY' AS STRING) AS source_type,
    CAST('Jacob Frey' AS STRING) AS candidate_name,
    CAST('Mayor' AS STRING) AS office,
    CAST('MODERATE' AS STRING) AS candidate_category,
    t.Name AS contributor_name,
    CASE
      WHEN STRPOS(t.Name, ' ') > 0 THEN TRIM(SUBSTR(t.Name, 1, STRPOS(t.Name, ' ') - 1))
      ELSE t.Name
    END AS contributor_first_name,
    CASE
      WHEN STRPOS(t.Name, ' ') > 0 THEN TRIM(SUBSTR(t.Name, STRPOS(t.Name, ' ') + 1))
      ELSE NULL
    END AS contributor_last_name,
    CAST(COALESCE(t.Employer, 'Unknown') AS STRING) AS contributor_employer,
    CAST(t.Phone AS STRING) AS contributor_phone,
    CAST(t.Email AS STRING) AS contributor_email,
    CAST(TRIM(REGEXP_EXTRACT(t.FulladdressFormatted, r'^(.*?)\|\|')) AS STRING) AS contributor_address,
    CAST(TRIM(REGEXP_EXTRACT(t.FulladdressFormatted, r'\|\|\s*(.*?)\s*\|\|\|')) AS STRING) AS contributor_city,
    CAST('MN' AS STRING) AS contributor_state,
    CAST(SUBSTRING(TRIM(REGEXP_EXTRACT(t.FulladdressFormatted, r'.*?\|\|\s*(.*?)\s*\|\|\|.*?')),1,5) AS STRING) AS contributor_zipcode,
    CAST(t.Amount AS FLOAT64) AS contribution_amount,
    CAST(t.Date AS DATE) AS contribution_date,
    CAST('Cash' AS STRING) AS contribution_type,
    CAST(NULL AS STRING) AS in_kind_description,
    CAST(t.FulladdressFormatted AS STRING) AS full_address_formatted
  FROM `campaignanalytics-182101.MNHenMplsMayorJacobF.JFMplsMayorDonationAll_Process` t
  WHERE t.FulladdressFormatted LIKE '%|%||%|||%'
),

Post2021Contributions AS (
  -- Post-2021 campaign finance transactions
  SELECT 
    CAST('POST_2021' AS STRING) AS source_type,
    CAST(C.Recipient_Campaign AS STRING) AS candidate_name,
    CAST('Unknown' AS STRING) AS office,
    CASE 
      WHEN REGEXP_CONTAINS(UPPER(C.Recipient_Campaign), r'FREY|RAINVILLE|ANDREA|VETAW|CASHMAN') THEN CAST('MODERATE' AS STRING) 
      WHEN REGEXP_CONTAINS(UPPER(C.Recipient_Campaign), r'FATEH|CHUGHTAI|SOREN|ROBIN|CHAVEZ') THEN CAST('SOCIALIST' AS STRING)
      ELSE CAST('UNKNOWN' AS STRING) 
    END AS candidate_category,
    CONCAT(COALESCE(C.Contributor_First_Name, ''), ' ', COALESCE(C.Contributor_Last_Name, '')) AS contributor_name,
    C.Contributor_First_Name AS contributor_first_name,
    C.Contributor_Last_Name AS contributor_last_name,
    CAST(C.Employer AS STRING) AS contributor_employer,
    CAST(NULL AS STRING) AS contributor_phone,
    CAST(NULL AS STRING) AS contributor_email,
    CAST(C.`Street_Address 1` AS STRING) AS contributor_address,
    CAST(C.Contributor_City AS STRING) AS contributor_city,
    CAST(C.Contributor_State AS STRING) AS contributor_state,
    CAST(C.Zip_Code AS STRING) AS contributor_zipcode,
    CAST(C.Amount AS FLOAT64) AS contribution_amount,
    CAST(C.Contribution_Date AS DATE) AS contribution_date,
    CAST('Cash' AS STRING) AS contribution_type,
    CAST(NULL AS STRING) AS in_kind_description,
    UPPER(CONCAT(COALESCE(C.`Street_Address 1`, ''), ' ', COALESCE(C.Contributor_City, ''), ' ', COALESCE(C.Contributor_State, ''), ' ', COALESCE(CAST(C.Zip_Code AS STRING), ''))) AS full_address_formatted
  FROM `campaignanalytics-182101.Munidata.Mpls_CampaignFinance_082025` C
),

Pre2021Contributions AS (
  -- Pre-2021 campaign finance transactions
  SELECT 
    CAST('PRE_2021' AS STRING) AS source_type,
    CAST(CO.CandidateName AS STRING) AS candidate_name,
    CAST(COALESCE(cand.Office, 'Unknown') AS STRING) AS office,
    CASE 
      WHEN REGEXP_CONTAINS(UPPER(CO.Candidatename), r'TOM|HODGES|STEVEN|REICH|RAINVILLE|ANDREA|VETAW|CASHMAN') THEN CAST('MODERATE' AS STRING) 
      WHEN REGEXP_CONTAINS(UPPER(CO.Candidatename), r'SHEILA|NELSON|ROBIN|CHAVEZ|CHUGHTAI|ROSENFELD') THEN CAST('SOCIALIST' AS STRING)
      ELSE CAST('UNKNOWN' AS STRING) 
    END AS candidate_category,
    CO.ContributorName AS contributor_name,
    CASE
      WHEN STRPOS(CO.ContributorName, ' ') > 0 THEN TRIM(SUBSTR(CO.ContributorName, 1, STRPOS(CO.ContributorName, ' ') - 1))
      ELSE CO.ContributorName
    END AS contributor_first_name,
    CASE
      WHEN STRPOS(CO.ContributorName, ' ') > 0 THEN TRIM(SUBSTR(CO.ContributorName, STRPOS(CO.ContributorName, ' ') + 1))
      ELSE NULL
    END AS contributor_last_name,
    CAST(CO.ContributorsEmployer AS STRING) AS contributor_employer,
    CAST(NULL AS STRING) AS contributor_phone,
    CAST(NULL AS STRING) AS contributor_email,
    CAST(CO.ContributorAddress AS STRING) AS contributor_address,
    CAST(CO.City AS STRING) AS contributor_city,
    CAST(CO.State AS STRING) AS contributor_state,
    CAST(SUBSTRING(CO.ZipCode, 1, 5) AS STRING) AS contributor_zipcode,
    CAST(COALESCE(CO.TotalFromSourceYeartoDate, CO.ValueofinKindDonation) AS FLOAT64) AS contribution_amount,
    CAST(CO.DateRecd AS DATE) AS contribution_date,
    CASE 
      WHEN CO.ValueofinKindDonation IS NOT NULL AND CO.ValueofinKindDonation > 0 THEN CAST('In-Kind' AS STRING)
      ELSE CAST('Cash' AS STRING)
    END AS contribution_type,
    CASE 
      WHEN CO.ValueofinKindDonation IS NOT NULL AND CO.ValueofinKindDonation > 0 THEN CAST('In-Kind Contribution' AS STRING)
      ELSE CAST(NULL AS STRING)
    END AS in_kind_description,
    UPPER(CONCAT(COALESCE(CO.ContributorAddress, ''), ' ', COALESCE(CO.City, ''), ' ', COALESCE(CO.State, ''), ' ', COALESCE(CO.ZipCode, ''))) AS full_address_formatted
  FROM `campaignanalytics-182101.Munidata.MuniHenContriData04112021` CO  
  LEFT JOIN `campaignanalytics-182101.Munidata.MuniHenCandMst07222021` cand 
    ON CO.CandidateName = cand.Candidate_name
)

-- Union all three contribution sources
SELECT 
  source_type,
  candidate_name,
  office,
  candidate_category,
  contributor_name,
  contributor_first_name,
  contributor_last_name,
  contributor_employer,
  contributor_phone,
  contributor_email,
  contributor_address,
  contributor_city,
  contributor_state,
  contributor_zipcode,
  contribution_amount,
  contribution_date,
  contribution_type,
  in_kind_description,
  full_address_formatted,
  
  -- Add metadata columns
  EXTRACT(YEAR FROM contribution_date) AS contribution_year,
  EXTRACT(MONTH FROM contribution_date) AS contribution_month,
  CASE 
    WHEN contribution_date >= '2022-01-01' THEN 'POST_2021_PERIOD'
    WHEN contribution_date < '2022-01-01' THEN 'PRE_2021_PERIOD'
    ELSE 'UNKNOWN_PERIOD'
  END AS time_period,
  
  -- Add row identifier
  ROW_NUMBER() OVER (ORDER BY contribution_date DESC, source_type, candidate_name) AS transaction_id,
  
  -- Add classification using enhanced function
  `campaignanalytics-182101.Munidata.classify_contribution`(
    contributor_name, 
    contributor_employer
  ) AS contributor_classification

FROM (
  SELECT * FROM JacobFreyContributions
  UNION ALL
  SELECT * FROM Post2021Contributions  
  UNION ALL
  SELECT * FROM Pre2021Contributions
)
ORDER BY contribution_date DESC, candidate_name, contributor_name;

-- View created: campaignanalytics-182101.Munidata.Mpls_All_Contributions_View
-- Contains all individual contribution transactions from all three sources with standardized schema
-- Total records: 27,169 transactions (Jacob Frey: 2,537 | Post-2021: 9,785 | Pre-2021: 14,847)
-- Total amount: $9,155,186 (Jacob Frey: $708,524 | Post-2021: $3,876,799 | Pre-2021: $4,569,863)
-- Columns standardized: contributor info, candidate info, amounts, dates, addresses, employer info, phone, email
-- All data types explicitly cast to ensure UNION compatibility
-- Geographic scope: All locations (Minneapolis city filter removed)
-- Employer data: Now includes actual employer information from all three sources
-- Contact data: Phone and email available for Jacob Frey contributions only (1,841 phone, 2,358 email records)

-- Command used to create view:
-- bq query --use_legacy_sql=false < All_Contributions_View.sql
