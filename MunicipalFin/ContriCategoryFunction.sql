-- Create a UDF that assigns contribution category based on employer name and contribution name 
CREATE OR REPLACE FUNCTION `campaignanalytics-182101.dq.dq_B_ContriCategory`(ContributorsEmployer STRING,ContributorName STRING) AS (
/*
 * Birchoo Data Processing functions 
 * dq_B_ContriCategory
 * input: String
 * returns: The contribution category for a given contribution Name 
 */
CASE
    WHEN ContributorsEmployer in (
                                  'North State Advisors',
                                  'Lockridge Grindal Nauen',
                                  'Attorney',
                                  'McGrann Shea Carnival Straughn and Lamb',
                                  'Dykema',
                                  'Faegre Baker Daniels',
                                  'Stinson Leonard Street',
                                  'Goff Public Relations',
                                  'Redmond Associates, Inc.',
                                  'Dominium',
                                  'Lobbyist',
                                  'Messerli Kramer',
                                  'Kaplan Strangis',
                                  'Faegre Baker Ds',
                                  'Faegre Baker D',
                                  'Brlol and Associates',
                                  'Lockridge Grindai Nauen',
                                  'Maslon, Edelman, Borman & Brand',
                                  'McGrann Shea C',
                                  'McGrahn Shea Carnival Stra',
                                  'North State Adv',
                                  'North State Advi',
                                  'Western Litigation'
                                  )   THEN 'Lawyer'
    WHEN (  Upper(trim(ContributorsEmployer)) Like '%HOFFNER %' OR
            Upper(trim(ContributorsEmployer)) Like '%LGN%' OR
            Upper(trim(ContributorsEmployer)) Like '%DYKEMA%' OR
            Upper(trim(ContributorsEmployer)) Like '% BAKER %' OR
            Upper(trim(ContributorsEmployer)) Like '%LINDQUIST%' OR
            Upper(trim(ContributorsEmployer)) Like '%ADVOCACY%'
            )  THEN 'Lawyer'
    WHEN ContributorsEmployer like '%Associate%' THEN 'Lawyer'
    WHEN ContributorsEmployer in (
                                  'Keller Williams Realty',
                                  'Developer',
                                  'Developers',
                                  'Hillcrest Develop',
                                  'Kraus Anderson',
                                  'Ryan Construction',
                                  'Weis Builders',
                                  'Brighton Development',
                                  'Mortenson Construction',
                                  'Mortensori Construction',
                                  'RSP Architects',
                                  'Building Manager',
                                  'Realtor',
                                  'Dunbar Development',
                                  'Keller Williams R',
                                  'Prospect Park Properties',
                                  'Ryan Companies',
                                  'Keller Williams Realty',
                                  'Kleinman Realty Company',
                                  'Opus Group',
                                  'Contractor',
                                  'Hyde Development',
                                  'Provident Real Estate Venture',
                                  'Thor Construction',
                                  'Thor Constructs',
                                  'Alatus',
                                  'Young Quinlan Building',
                                  'Hillcrest Development',
                                  'Wellington Development',
                                  'Lupe Development',
                                  'Abdo Market House',
                                  'StevenScott Management',
                                  'Duval Development',
                                  'Welsh Companies',
                                  'Lakes Area Realty'                                
                                  ) THEN 'Developer'
    WHEN (  Upper(trim(ContributorsEmployer)) Like '%DORAN %' OR
            Upper(trim(ContributorsEmployer)) Like '%CPM COMPANIES%' OR
            Upper(trim(ContributorsEmployer)) Like '%RYAN CO%' OR
            Upper(trim(ContributorsEmployer)) Like '%WINDSOR MANAG%' OR
            Upper(trim(ContributorsEmployer)) Like '%PROPERTIES%' OR
            Upper(trim(ContributorsEmployer)) Like '%ACKERBERG%' OR
            Upper(trim(ContributorsEmployer)) Like '%PROP %' OR
            Upper(trim(ContributorsEmployer)) Like '%SOLHEM%' OR
            Upper(trim(ContributorsEmployer)) Like '%LANDER%' OR
            Upper(trim(ContributorsEmployer)) Like '%DEVELOPMENT%' OR
            Upper(trim(ContributorsEmployer)) Like '%SCHAFER%' OR
            Upper(trim(ContributorsEmployer)) Like '%MANAGEMENT%' OR
            Upper(trim(ContributorsEmployer)) Like '%METROPELIGO%' OR
            Upper(trim(ContributorsEmployer)) Like '%COLDWELL%' OR
            Upper(trim(ContributorsEmployer)) Like '%BANKER%' OR
            Upper(trim(ContributorsEmployer)) Like '%GRECO%' OR
            Upper(trim(ContributorsEmployer)) Like '%HOSPITALITY%' OR
            Upper(trim(ContributorsEmployer)) Like '%DESIGN%' OR
            Upper(trim(ContributorsEmployer)) Like '%COMMERCIAL%' OR
            Upper(trim(ContributorsEmployer)) Like '%BKV %' OR
            Upper(trim(ContributorsEmployer)) Like '%MORTENSON%' OR
            Upper(trim(ContributorsEmployer)) Like '%COLLIERS%' OR
            Upper(trim(ContributorsEmployer)) Like '%REAL ESTATE%' OR
            Upper(trim(ContributorsEmployer)) Like '%FRANA%' OR
            Upper(trim(ContributorsEmployer)) Like '%LOUCKS%' OR
            Upper(trim(ContributorsEmployer)) Like '%PERKINS%' OR
            Upper(trim(ContributorsEmployer)) Like '%ARCHITECT%' 
            ) THEN 'Developer'
    WHEN ContributorsEmployer in (
                                  'Ramsey Excavating',
                                  'Timeshare Systems',
                                  'Kelber Catering',
                                  'Kelber Cateririg',
                                  'Kelber Catering',
                                  'Keiber Catering',
                                  'Minnesota Vikings',
                                  'Broadway Liquor',
                                  'Hirshfields',
                                  'Minnesota Twins',
                                  'Minnesota Twins Suite 3900',
                                  'Delta Dental Foundation',
                                  'Restauranteur',
                                  'Sheehan Develo',
                                  'Wall Companies',
                                  'Dakota Jazz Club',
                                  'March Enterprises',
                                  'Le Meredien Chambers',
                                  'Atomic Recycling',
                                  'Pohlad Companies',
                                  'Businessman',
                                  'The Language Bank',
                                  'Dunbar Enterprises',
                                  'Wells Fargo',
                                  'Standard Heating and Air',
                                  'Blue Ox',
                                  'Minnesota Timberwolves',
                                  'Minnesota Twins',
                                  "Hirshfield's",
                                  'Minnesota Timberwoives',
                                  "Jerry's Foods",
                                  'Parasole Restaurants',
                                  'kelber Catering',
                                  'Atomic Recyclinc',
                                  'Atomic Recycling',
                                  'Base Management LLC',
                                  'Minneapolis Entertainment, Inc.',
                                  'Deja Vu of Minnesota',
                                  'Dunbar Enterprise',
                                  'March Enterprise',
                                  'Rae Mackenzie Group',
                                  'Welcome Matters',
                                  'Chowgirls Catering',
                                  'Wander North Distillery',
                                  'Tate & Setterlund'
                                  )  THEN 'BusinessOwner' 
    WHEN (  Upper(trim(ContributorsEmployer)) Like '%WINE%' OR
            Upper(trim(ContributorsEmployer)) Like '%NEWBERRY%' OR
            Upper(trim(ContributorsEmployer)) Like '%STUDIO%' OR
            Upper(trim(ContributorsEmployer)) Like '%NUWAY%' OR
            Upper(trim(ContributorsEmployer)) Like '%HK&OK%' OR
            Upper(trim(ContributorsEmployer)) Like '%OUTDOOR%' OR
            Upper(trim(ContributorsEmployer)) Like '%BARR %' OR
            Upper(trim(ContributorsEmployer)) Like '%MAHAL%' OR
            Upper(trim(ContributorsEmployer)) Like '%UROLOGY%' OR
            Upper(trim(ContributorsEmployer)) Like '%CHERRYHOMES%' OR
            Upper(trim(ContributorsEmployer)) Like '%TACO%' OR
            Upper(trim(ContributorsEmployer)) Like '%TURKEY%' OR
            Upper(trim(ContributorsEmployer)) Like '%DERMATOLOG%' OR
            Upper(trim(ContributorsEmployer)) Like '%EVENT%' OR
            Upper(trim(ContributorsEmployer)) Like '%BACHELOR%' OR
            Upper(trim(ContributorsEmployer)) Like '%PLATE%' OR
            Upper(trim(ContributorsEmployer)) Like '%TOWING%' OR
            Upper(trim(ContributorsEmployer)) Like '%CAFE%' OR
            Upper(trim(ContributorsEmployer)) Like '%MEADOW%' OR
            Upper(trim(ContributorsEmployer)) Like '%KNOWRE%' OR
            Upper(trim(ContributorsEmployer)) Like '%LIGHTWELL%' OR
            Upper(trim(ContributorsEmployer)) Like '%MAKES IT%' OR
            Upper(trim(ContributorsEmployer)) Like '%MASTER%' OR
            Upper(trim(ContributorsEmployer)) Like '%MENTOR PLANET%' OR
            Upper(trim(ContributorsEmployer)) Like '%NINA%' OR
            Upper(trim(ContributorsEmployer)) Like '%NORTH%' OR
            Upper(trim(ContributorsEmployer)) Like '%PRESS%' OR
            Upper(trim(ContributorsEmployer)) Like '%RC ENTER%' OR
            Upper(trim(ContributorsEmployer)) Like '%SOLHE%' OR
            Upper(trim(ContributorsEmployer)) Like '%HEN %' OR
            Upper(trim(ContributorsEmployer)) Like '%URBANWORK%' OR
            Upper(trim(ContributorsEmployer)) Like '%OPTIMISTIC%' 
            ) THEN 'BusinessOwner'
    WHEN ContributorName = 'David, Wilson and Michael Peterman' THEN 'BusinessOwner'
    WHEN ContributorsEmployer in (
                                  'Minneapolis City Council',
                                  'Lerner Publishing',
                                  'CenturyLink',
                                  'Alliha',
                                  'Capella University',
                                  'Realtor',
                                  'Minneapolis Fire',
                                  'Reliable Transportation',
                                  'Meet Minneapolis',
                                  'Ameriprise Finan',
                                  'Leamington Company',
                                  'American Academy of Neurology',
                                  'Jefferson Lines',
                                  'MRI',                                  
                                  'CEE Center',
                                  'Seif Employed',
                                  'Allina',
                                  'Graco',
                                  'Wells Fargo',
                                  'Target',
                                  'Jerrys Foods',
                                  'Solar Arts',
                                  'Minneapolis Entertainment, inc.',
                                  'C Biz',
                                  'The Fish Guys',
                                  'Larkin Hoffman',
                                  'Shaw Lundquist',
                                  'Pfizer',
                                  'City of Edina',
                                  'Minneapolis Loppet',
                                  'Weils Fargo',
                                  'TCP Bank',
                                  'North Metro Mayors Association',
                                  'tnsperity',
                                  'Finance Executive',
                                  'Minnesota Vikings',
                                  'Shafer Richards',
                                  'Xcel Energy',
                                  'Summit Academy',
                                  'MN Dept of Human Services',
                                  'Student',
                                  'Consultant',
                                  'AECOM',
                                  'Lerrier Publishing',
                                  'NRG Energy',
                                  'Dip Vu of Minnesota',
                                  'Normandy Hotel',
                                  'Kowalskis',
                                  'Urban Works',
                                  'Walker Art Center',
                                  'PJ Hafiz Club Inc',
                                  'The Rotunda Group',
                                  'River Liquors',
                                  'Health Partners',
                                  'US Benchcorp',
                                  'Homemaker',
                                  'Minneapolis Dow',
                                  'Hubbard Broadcasting',
                                  'Hennepin Theatre Trust',
                                  'Nuway',
                                  'Key Investments',
                                  'Wefts Fargo',
                                  'Standard Heating' ,
                                  'Meet Minneapoli',
                                  'The Rotunda Gr',
                                  'Young Quinian B'
                                    ) THEN 'Individual'
    WHEN (  Upper(trim(ContributorsEmployer)) Like '%U OF M%' OR
            Upper(trim(ContributorsEmployer)) Like '%SCHOOL%' OR
            Upper(trim(ContributorsEmployer)) Like '%CAMP%' OR
            Upper(trim(ContributorsEmployer)) Like '%TARGET%' OR
            Upper(trim(ContributorsEmployer)) Like '%ACCENTURE%' OR
            Upper(trim(ContributorsEmployer)) Like '%MACY%' OR
            Upper(trim(ContributorsEmployer)) Like '%UNIVERSITY%' OR
            Upper(trim(ContributorsEmployer)) Like '%METRO TRANSIT%' OR
            Upper(trim(ContributorsEmployer)) Like '%ITDP%' OR
            Upper(trim(ContributorsEmployer)) Like '%COUNTY%' OR
            Upper(trim(ContributorsEmployer)) Like '%TRUST%' OR
            Upper(trim(ContributorsEmployer)) Like '%BOARD%' OR
            Upper(trim(ContributorsEmployer)) Like '%EMPLOYED%' OR
            Upper(trim(ContributorsEmployer)) Like '%SOCIETY%' OR
            Upper(trim(ContributorsEmployer)) Like '%BART%' OR
            Upper(trim(ContributorsEmployer)) Like '%CPM%' OR
            Upper(trim(ContributorsEmployer)) Like '%CITY%' OR
            Upper(trim(ContributorsEmployer)) Like '%CONSULT%' OR
            Upper(trim(ContributorsEmployer)) Like '%GREAT RIVER%' OR
            Upper(trim(ContributorsEmployer)) Like '%PROFESSIONAL%' OR
            Upper(trim(ContributorsEmployer)) Like '%MAYOR%' OR
            Upper(trim(ContributorsEmployer)) Like '%NEIGH%' OR
            Upper(trim(ContributorsEmployer)) Like '%US BANK%' OR
            Upper(trim(ContributorsEmployer)) Like '%WCW%' OR
            Upper(trim(ContributorsEmployer)) Like '%UNIVERSIT%' OR
            Upper(trim(ContributorsEmployer)) Like '%ARMY CORP%' 
            ) THEN  'Individual'
    WHEN ( upper(trim(ContributorsEmployer)) ='RETIRED' OR upper(trim(ContributorsEmployer)) like 'SELF%' OR  trim(ContributorsEmployer) in ('Minneapolis Public Schools','State of Minnesota','City of Minneapolis')) 
         THEN  'Individual' 
    WHEN ContributorsEmployer like '%Minneapolis City Council%' THEN 'Individual'
    WHEN Upper(trim(ContributorName)) Like '%POHLAD%' THEN 'Pohlad family'
    WHEN ( 
          (ContributorsEmployer is null or upper(trim(ContributorsEmployer)) ='N/A' or upper(trim(ContributorsEmployer)) = '-' )
          AND 
          (Upper(trim(ContributorName)) Like '%COUNCIL%' OR
            Upper(trim(ContributorName)) Like '%COMMITTEE%' OR
            Upper(trim(ContributorName)) Like '%UNION%' OR
            Upper(trim(ContributorName)) Like '%CITY%' OR
            Upper(trim(ContributorName)) Like '%VOLUNTEER%' OR
            Upper(trim(ContributorName)) Like '%PAC%' OR
            Upper(trim(ContributorName)) Like '%FUND%' OR
            Upper(trim(ContributorName)) Like '%LLC%' OR
            Upper(trim(ContributorName)) Like '%POLITICAL%' OR
            Upper(trim(ContributorName)) Like '%ASSOCIATION%' OR
            Upper(trim(ContributorName)) Like '%INC%' OR
            Upper(trim(ContributorName)) Like '%FRIENDS%' OR
            Upper(trim(ContributorName)) Like '%LOCAL%' OR
            Upper(trim(ContributorName)) Like '%DISTRICT%' OR
            Upper(trim(ContributorName)) Like '%LLP%' OR
            Upper(trim(ContributorName)) Like '%STATE%' OR
            Upper(trim(ContributorName)) Like '%LAW%' OR
            Upper(trim(ContributorName)) Like '%LABOR%' OR
            Upper(trim(ContributorName)) Like '%MINNEAPOLIS%' OR
            Upper(trim(ContributorName)) Like '%FEDERATION%' OR
            Upper(trim(ContributorName)) Like '%SELU%' OR
            Upper(trim(ContributorName)) Like '%SEIU%' OR
            Upper(trim(ContributorName)) Like '%FIRE FIGHTERS%' OR
            Upper(trim(ContributorName)) Like '%MINNESOTA%' OR
            Upper(trim(ContributorName)) Like '%ATTORNEY%'  
            )) THEN 'Association'
    WHEN ContributorsEmployer in ('Political Education Fund',
                                  'Political Action Committee',
                                  'Minnesota Retail Grocers Association') THEN 'Association'
    WHEN (Upper(trim(ContributorName)) Like '%COUNCIL%' OR
            Upper(trim(ContributorName)) Like '%COMMITTEE%' OR
            Upper(trim(ContributorName)) Like '%UNION%' OR
            Upper(trim(ContributorName)) Like '%CITY%' OR
            Upper(trim(ContributorName)) Like '%VOLUNTEER%' OR
            Upper(trim(ContributorName)) Like '%PAC%' OR
            Upper(trim(ContributorName)) Like '%FUND%' OR
            Upper(trim(ContributorName)) Like '%LLC%' OR
            Upper(trim(ContributorName)) Like '%POLITICAL%' OR
            Upper(trim(ContributorName)) Like '%ASSOCIATION%' OR
            Upper(trim(ContributorName)) Like '%ASSOC%' OR
            Upper(trim(ContributorName)) Like '%INC%' OR
            Upper(trim(ContributorName)) Like '%FRIENDS%' OR
            Upper(trim(ContributorName)) Like '%LOCAL%' OR
            Upper(trim(ContributorName)) Like '%DISTRICT%' OR
            Upper(trim(ContributorName)) Like '%LLP%' OR
            Upper(trim(ContributorName)) Like '%STATE%' OR
            Upper(trim(ContributorName)) Like '%LAW%' OR
            Upper(trim(ContributorName)) Like '%LABOR%' OR
            Upper(trim(ContributorName)) Like '%MINNEAPOLIS%' OR
            Upper(trim(ContributorName)) Like '%FEDERATION%' OR
            Upper(trim(ContributorName)) Like '%SELU%' OR
            Upper(trim(ContributorName)) Like '%SEIU%' OR
            Upper(trim(ContributorName)) Like '%FIRE FIGHTERS%' OR
            Upper(trim(ContributorName)) Like '%MINNESOTA%' OR
            Upper(trim(ContributorName)) Like '%ATTORNEY%' OR
            Upper(trim(ContributorName)) Like '%MULTI%' OR
            Upper(trim(ContributorName)) Like '%XCEL%' OR
            Upper(trim(ContributorName)) Like '%UNITE%' OR
            Upper(trim(ContributorName)) Like '%AFL-CIO%' OR
            Upper(trim(ContributorName)) Like '%TRADE%'
         ) THEN 'Association'
    WHEN (  Upper(trim(ContributorsEmployer)) Like '%AFL-CIO%' OR
            Upper(trim(ContributorsEmployer)) Like '%SEIU%' OR
            Upper(trim(ContributorsEmployer)) Like '%COMMUNITY%' OR
            Upper(trim(ContributorsEmployer)) Like '%RIGHTS%' OR
            Upper(trim(ContributorsEmployer)) Like '%GREEN%' OR
            Upper(trim(ContributorsEmployer)) Like '%ALLIANCE%' OR
            Upper(trim(ContributorsEmployer)) Like '%MINNESOTA%' OR
            Upper(trim(ContributorsEmployer)) Like '%COALIT%' OR
            Upper(trim(ContributorsEmployer)) Like '%TAKE ACTION%' OR
            Upper(trim(ContributorsEmployer)) Like '%GROUP%' OR
            Upper(trim(ContributorsEmployer)) Like '%WILDLIFE%' OR
            Upper(trim(ContributorsEmployer)) Like '%ULI MN%' OR
            Upper(trim(ContributorsEmployer)) Like '%COUNCIL%' 
        ) THEN 'Association'
    ELSE 'Others'
END 
)