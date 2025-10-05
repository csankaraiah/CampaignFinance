
CREATE OR REPLACE FUNCTION `campaignanalytics-182101.MNHenMplsMayorJacobF.enhanced_classify_contribution`(
    contributor_name STRING,
    contributor_employer STRING,
    contribution_amount FLOAT64
) RETURNS STRING AS (
    CASE
        -- Enhanced classification rules based on analysis
        WHEN UPPER(contributor_employer) LIKE '%LAW%' 
            OR UPPER(contributor_employer) LIKE '%ATTORNEY%' 
            OR UPPER(contributor_employer) LIKE '%LEGAL%' 
        THEN 'Lawyer'
        
        WHEN UPPER(contributor_employer) LIKE '%DEVELOP%' 
            OR UPPER(contributor_employer) LIKE '%CONSTRUCTION%' 
            OR UPPER(contributor_employer) LIKE '%REAL ESTATE%'
        THEN 'Developer'
        
        WHEN UPPER(contributor_employer) LIKE '%POHLAD%'
            OR UPPER(contributor_name) LIKE '%POHLAD%'
        THEN 'Pohlad'
        
        WHEN UPPER(contributor_employer) LIKE '%ASSOCIATION%'
            OR UPPER(contributor_employer) LIKE '%UNION%'
            OR UPPER(contributor_employer) LIKE '%PAC%'
        THEN 'Association'
        
        WHEN contributor_employer IS NULL 
            OR TRIM(contributor_employer) = ''
            OR UPPER(contributor_employer) = 'RETIRED'
            OR UPPER(contributor_employer) = 'SELF'
        THEN 'Individual'
        
        WHEN UPPER(contributor_employer) LIKE '%CEO%'
            OR UPPER(contributor_employer) LIKE '%PRESIDENT%'
            OR UPPER(contributor_employer) LIKE '%OWNER%'
            OR UPPER(contributor_employer) LIKE '%FOUNDER%'
        THEN 'BusinessOwner'
        
        ELSE 'Others'
    END
);

-- Enhanced classification analysis summary:
-- Total records analyzed: 27,159
-- Category distribution:
-- Individual: 9,568 (35.2%)
-- Others: 9,221 (34.0%)
-- BusinessOwner: 4,725 (17.4%)
-- Developer: 1,567 (5.8%)
-- Association: 1,095 (4.0%)
-- Lawyer: 983 (3.6%)
-- Generated on: 2025-10-05 07:07:29
