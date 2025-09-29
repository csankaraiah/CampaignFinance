-- This file returns all associations from MuniHenAssocDtlETL (master) with two additional columns
-- Contri_Amt and conti_count derived by fuzzy-matching to contribution sources (AssocContri)

-- Final single-query: master = MuniHenAssocDtlETL (expected 199 rows)
-- Returns one row per master association with two additional columns: Contri_Amt and conti_count

WITH AssocContri AS (
  -- aggregate candidate names/employers from both contribution sources
  SELECT
    ContributorName,
    ContributorsEmployer,
    SUM(conti_count) AS conti_count,
    SUM(Contri_Amt) AS Contri_Amt
  FROM (
    SELECT
      CONCAT(Contributor_First_Name, ' ', Contributor_Last_Name) AS ContributorName,
      Employer AS ContributorsEmployer,
      COUNT(*) AS conti_count,
      CAST(SUM(Amount) AS INT64) AS Contri_Amt
    FROM `campaignanalytics-182101.Munidata.Mpls_CampaignFinance_082025`
    WHERE `campaignanalytics-182101.dq.dq_B_ContriCategory`(Employer, '') = 'Association'
       OR `campaignanalytics-182101.dq.dq_B_ContriCategory`(CONCAT(Contributor_First_Name,' ',Contributor_Last_Name), '') = 'Association'
    GROUP BY 1,2

    UNION ALL

    SELECT
      ContributorName,
      ContributorsEmployer,
      COUNT(*) AS conti_count,
      SUM(TotalFromSourceYeartoDate) AS Contri_Amt
    FROM `campaignanalytics-182101.Munidata.MuniHenContriData04112021`
    WHERE `campaignanalytics-182101.dq.dq_B_ContriCategory`(ContributorsEmployer, ContributorName) = 'Association'
    GROUP BY 1,2
  )
  GROUP BY ContributorName, ContributorsEmployer
),
MasterNames AS (
  -- use full association detail table as master; include all columns (keep AssociationName for matching)
  -- deduplicate so there is only one row per (FormattedFullAddress, FormattedPhoneNumber)
  SELECT
    * EXCEPT(rn)
  FROM (
    SELECT
      t.*,
      t.ContributorName AS AssociationName,
      ROW_NUMBER() OVER (
        PARTITION BY COALESCE(t.FormattedFullAddress, ''), COALESCE(t.FormattedPhoneNumber, '')
        ORDER BY t.ContributorName
      ) AS rn
    FROM `campaignanalytics-182101.Munidata.MuniHenAssocDtlETL` t
  )
  WHERE rn = 1
),
Candidates AS (
  -- join master names to candidate contributions with pre-filters to limit pairs
  SELECT
    m.AssociationName,
    a.ContributorName AS cand_name,
    a.ContributorsEmployer AS cand_employer,
    a.Contri_Amt,
    a.conti_count,
    -- distances
    EDIT_DISTANCE(UPPER(TRIM(m.AssociationName)), UPPER(TRIM(a.ContributorName))) AS dist_name,
    EDIT_DISTANCE(UPPER(TRIM(m.AssociationName)), UPPER(TRIM(a.ContributorsEmployer))) AS dist_emp,
    -- normalized distances
    SAFE_DIVIDE(EDIT_DISTANCE(UPPER(TRIM(m.AssociationName)), UPPER(TRIM(a.ContributorName))), GREATEST(LENGTH(m.AssociationName), LENGTH(a.ContributorName))) AS norm_name,
    SAFE_DIVIDE(EDIT_DISTANCE(UPPER(TRIM(m.AssociationName)), UPPER(TRIM(a.ContributorsEmployer))), GREATEST(LENGTH(m.AssociationName), LENGTH(a.ContributorsEmployer))) AS norm_emp,
    -- similarity scores computed separately against name and employer
    CASE
      WHEN UPPER(TRIM(m.AssociationName)) = UPPER(TRIM(a.ContributorName)) THEN 1.0
      WHEN STRPOS(UPPER(m.AssociationName), UPPER(a.ContributorName)) > 0 OR STRPOS(UPPER(a.ContributorName), UPPER(m.AssociationName)) > 0 THEN 0.9
      WHEN SOUNDEX(UPPER(m.AssociationName)) = SOUNDEX(UPPER(a.ContributorName)) AND EDIT_DISTANCE(UPPER(TRIM(m.AssociationName)), UPPER(TRIM(a.ContributorName))) <= 5 THEN 0.8
      WHEN SAFE_DIVIDE(EDIT_DISTANCE(UPPER(TRIM(m.AssociationName)), UPPER(TRIM(a.ContributorName))), GREATEST(LENGTH(m.AssociationName), LENGTH(a.ContributorName))) <= 0.25 THEN 0.7
      WHEN SAFE_DIVIDE(EDIT_DISTANCE(UPPER(TRIM(m.AssociationName)), UPPER(TRIM(a.ContributorName))), GREATEST(LENGTH(m.AssociationName), LENGTH(a.ContributorName))) <= 0.40 THEN 0.5
      ELSE 0.0
    END AS score_name,
    CASE
      WHEN UPPER(TRIM(m.AssociationName)) = UPPER(TRIM(a.ContributorsEmployer)) THEN 1.0
      WHEN STRPOS(UPPER(m.AssociationName), UPPER(a.ContributorsEmployer)) > 0 OR STRPOS(UPPER(a.ContributorsEmployer), UPPER(m.AssociationName)) > 0 THEN 0.9
      WHEN SOUNDEX(UPPER(m.AssociationName)) = SOUNDEX(UPPER(a.ContributorsEmployer)) AND EDIT_DISTANCE(UPPER(TRIM(m.AssociationName)), UPPER(TRIM(a.ContributorsEmployer))) <= 5 THEN 0.8
      WHEN SAFE_DIVIDE(EDIT_DISTANCE(UPPER(TRIM(m.AssociationName)), UPPER(TRIM(a.ContributorsEmployer))), GREATEST(LENGTH(m.AssociationName), LENGTH(a.ContributorsEmployer))) <= 0.25 THEN 0.7
      WHEN SAFE_DIVIDE(EDIT_DISTANCE(UPPER(TRIM(m.AssociationName)), UPPER(TRIM(a.ContributorsEmployer))), GREATEST(LENGTH(m.AssociationName), LENGTH(a.ContributorsEmployer))) <= 0.40 THEN 0.5
      ELSE 0.0
    END AS score_emp
  FROM MasterNames m
  LEFT JOIN AssocContri a
    ON (
      -- prefilter: at least one of these should hold to consider pair
      STRPOS(UPPER(m.AssociationName), UPPER(a.ContributorName)) > 0
      OR STRPOS(UPPER(a.ContributorName), UPPER(m.AssociationName)) > 0
      OR STRPOS(UPPER(m.AssociationName), UPPER(a.ContributorsEmployer)) > 0
      OR STRPOS(UPPER(a.ContributorsEmployer), UPPER(m.AssociationName)) > 0
      OR SOUNDEX(UPPER(m.AssociationName)) = SOUNDEX(UPPER(a.ContributorName))
      OR SOUNDEX(UPPER(m.AssociationName)) = SOUNDEX(UPPER(a.ContributorsEmployer))
      OR EDIT_DISTANCE(UPPER(TRIM(m.AssociationName)), UPPER(TRIM(a.ContributorName))) <= GREATEST(LENGTH(m.AssociationName), LENGTH(a.ContributorName)) * 0.4
      OR EDIT_DISTANCE(UPPER(TRIM(m.AssociationName)), UPPER(TRIM(a.ContributorsEmployer))) <= GREATEST(LENGTH(m.AssociationName), LENGTH(a.ContributorsEmployer)) * 0.4
    )
),
Ranked AS (
  -- combine scores and pick best candidate per master association
  SELECT
    AssociationName,
    cand_name,
    cand_employer,
    Contri_Amt,
    conti_count,
    GREATEST(score_name, score_emp) AS score,
    LEAST(IFNULL(dist_name, 9999), IFNULL(dist_emp, 9999)) AS dist,
    ROW_NUMBER() OVER (PARTITION BY AssociationName ORDER BY GREATEST(score_name, score_emp) DESC, LEAST(IFNULL(dist_name,9999), IFNULL(dist_emp,9999)) ASC) AS rn
  FROM Candidates
)
SELECT
  m.*,
  COALESCE(r.Contri_Amt, 0) AS Contri_Amt,
  COALESCE(r.conti_count, 0) AS conti_count
FROM MasterNames m
LEFT JOIN Ranked r
  ON m.AssociationName = r.AssociationName AND r.rn = 1
ORDER BY m.AssociationName;
