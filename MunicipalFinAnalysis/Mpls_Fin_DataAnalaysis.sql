
-- Analysis 1 : Municipal contribution data analysis

--Query to get contribution data for all mayoral candidates
select 
CandidateName, 
sum(TotalFromSourceYeartoDate),
count(*)
 from Munidata.MuniHenContriData04112021 contri join 
 Munidata.MuniHenCandMst07222021 cand on 
contri.CandidateName = cand.Candidate_name 
where cand.Office = 'Mayor'
 group by 1 
 order by 2 desc;



-- Analysis 1.1 : Association contribution analysis
-- Query to get association total contribution along with contact details 

