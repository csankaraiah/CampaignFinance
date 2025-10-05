
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
-- Others: 11,473 (42.2%)
-- Individual: 9,850 (36.3%)
-- Association: 2,179 (8.0%)
-- Developer: 1,851 (6.8%)
-- Lawyer: 927 (3.4%)
-- BusinessOwner: 821 (3.0%)
-- Pohlad family: 58 (0.2%)
-- Generated on: 2025-10-05 07:05:21
