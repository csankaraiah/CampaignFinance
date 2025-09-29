# This project analyze various finance data that are associated with political campaign contribution

## First one that this project will focus is on municiple city elections and contribution associated with that


### Analysis 1 : Municipal contribution data
This analysis has queries that analyze contribution data for mayoral candidates.

Here are the key tables that are used in this analysis:

Munidata.MuniHenContriData04112021 : 
This table has contribution data that was build by processing all the camapign fillings on Hennepin county website prior to 2022 election.
Record count - 13498

`campaignanalytics-182101.Munidata.Mpls_CampaignFinance_082025` : 
This table has contribution data for minneapolis city elections since 2022 when the campaign finance reporting moved away from hennepin county to city level reporting. This data is much more structured and can be easily downloaded from the website


`campaignanalytics-182101.MNHenMplsMayorJacobF.JFMplsMayorDonationAll_Process`
This table has contribution data for minneapolis mayoral candidate Jacob Frey. This data was processed for campaign finance filling purpose and is more structured.


Munidata.MuniHenExpData03102021 :
This table has the expenditure data for all the candidates that ran for office upto 2021 election cycle.
Record count - 6077

Munidata.MuniHenCandMst07222021 :
This table has the candidate master data for all the candidates that ran for office upto 2021 election cycle.
Record count - 392

#### Analyze the donor types, likelihood and amount of donation based on donor type. 

#### Analysis 1.1 : Association contribution analysis

Table Name: Munidata.MNAssociationData :
This is association master table that has list of all the associations that has potential to contribute to campaigns 
Number of Rows: 693

Table Name: Munidata.MuniHenAssocMst
Number of Rows: 228
This table has the association master data for all the associations that contributed to municipal campaigns

Table Name: Munidata.MuniHenAssocMatchETL
Number of Rows: 228
This table has the association match data for all the associations that contributed to municipal campaigns

Table Name: MuniHenAssocDtlETL
Number of Rows: 199
This table has the association detail data for all the associations that contributed to municipal campaigns


#### Analysis 1.1 : Association contribution analysis

