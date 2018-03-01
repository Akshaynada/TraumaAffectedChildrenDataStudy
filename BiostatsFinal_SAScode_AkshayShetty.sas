 
/* Change the infile for the MasterSDQ file*/ 
 
data child_master; 
	length visit $ 10; 
	infile "/folders/myfolders/SASFinalProjectAkshayShetty/Master_Child_SDQ.csv" dsd FIRSTOBS=2; 
	input subjNum  
	subjGender $ 
	subjage 
	visit $ 
	sdq_ess 
	sdq_cps 
	sdq_iha 
	sdq_pps 
	sdq_psb	 
	ranNum; 
run; 
 
/* This is my sample for the final project , RanNum = 37 */ 
data child_sample; 
set child_master(where=(rannum=37)); 
run; 
 
/* The overall macro  
  * use ExecuteSASprograms(<Nameofthedataset>, <Two level categorical variable>) 
  * Nameofthedataset = child_sample ( my random number is 37) 
  * Two level categorical value = SubjGender , I have used it in the sdq vs gender stats 
*/ 
 
/* Question 1 */ 
 
/* Create variable absent, absent=1 if not visit NA or not gone*/ 
%MACRO ExecuteSASprograms(child_dataset, two_level_var); 
 
data &child_dataset; 
set &child_dataset; 
if missing(sdq_psb) then absent=1; 
	else absent=0; 
run; 
 
proc freq data=&child_dataset; 
title "Number and frequencies of children at each assessement"; 
table visit*absent /nocol nopercent; 
run; 
 
/* Question 2*/ 
ODS SELECT NONE; 
PROC TABULATE data=&child_dataset out=child_miss; 
var absent; 
class subjnum; 
tables subjnum, sum=absent*'Absent'; 
run; 
 
ODS SELECT ALL; 
proc freq data=child_miss; 
title "Absent_sum=0 means no visits missed, Absent_sum = <1,2,3> means 1 , 2 or 3 visits missed"; 
table absent_sum /nocol; 
run; 
 
/* Question 3 */ 
 
/* Create an additional dataset from child_sample */ 
Data child_sample_1; 
set &child_dataset; 
run; 
 
/* Remove NA rows for not visited */ 
proc sql; 
delete * from child_sample_1 where sdq_psb=.; 
quit; 
 
/* Keep subjnum and the visits */ 
proc sql; 
create table child_sample_1_temp as 
select subjnum, visit from child_sample_1; 
quit; 
 
proc transpose data=child_sample_1_temp out=child_sample_1_temp_wide; 
    by subjnum ; 
    id visit; 
    var visit; 
run; 
 
/* B     - only baseline visit  
 * BE    - Baseline and Exit 
 * BF1   - Baseline and Followup1 
 * BF2   - Basline and Followup2   
 * BEF1  - Baseline, Exit and Followup1 
 * BEF2  - Baseline, Exit and Followup2 
 * BEF1F2 - Visited all  
 */ 
 
data child_sample_1_wide; 
set child_sample_1_temp_wide; 
array assess{4} Baseline Exit Followup1 Followup2; 
if assess{1} ne '' and assess{2} ne '' and assess{3} ne '' and assess{4} ne '' then Assessmentlevels = 'BEF1F2'; 
else if assess{1} ne '' and assess{2} ne '' and assess{3} ne '' then Assessmentlevels = 'BEF1'; 
else if assess{1} ne '' and assess{2} ne '' and assess{4} ne '' then Assessmentlevels = 'BEF2'; 
else if assess{1} ne '' and assess{3} ne '' and assess{4} ne '' then Assessmentlevels = 'BF1F2'; 
else if assess{1} ne '' and assess{2} ne '' then Assessmentlevels = 'BE'; 
else if assess{1} ne '' and assess{3} ne '' then Assessmentlevels = 'BF1'; 
else if assess{1} ne '' and assess{4} ne '' then Assessmentlevels = 'BF2'; 
else if assess{1} ne '' then Assessmentlevels = 'B'; 
drop i; 
run; 
 
proc freq data=child_sample_1_wide; 
title "Frequency and Percentage for levels of Assessments"; 
table Assessmentlevels /nocol; 
run; 
 
 
/* Question 4 */ 
%MACRO GetSDQSummary(child_set, sdqvar, gender); 
proc tabulate data=&child_set; 
title "Summary for &sdqvar over the total sample"; 
class visit; 
var &sdqvar; 
table visit * &sdqvar, mean stddev sum n; 
run; 
 
proc tabulate data=child_sample; 
title "Summary for &sdqvar vs &gender"; 
class visit &gender; 
var &sdqvar; 
table visit * &gender * &sdqvar, mean stddev sum n; 
run; 
%MEND GetSDQSummary; 
 
%GetSDQSummary(&child_dataset, sdq_psb, &two_level_var); 
%GetSDQSummary(&child_dataset, sdq_pps, &two_level_var); 
%GetSDQSummary(&child_dataset, sdq_iha, &two_level_var); 
%GetSDQSummary(&child_dataset, sdq_cps, &two_level_var); 
%GetSDQSummary(&child_dataset, sdq_ess, &two_level_var); 
 
/* Question 5 */ 
 
/* Create a copy of the dataset to manipulate */ 
DATA child_sample_part5; 
set child_sample; 
Run; 
 
/* Remove duplicate entries */ 
proc sql; 
delete from child_sample_part5 where sdq_psb=. ;  
quit; 
 
/*Order the dataset by subjnum and then find the first and last entry levels*/ 
data child_sample_part5; 
	set child_sample_part5; 
	by Subjnum; 
	/*Get the details on the which is the last assessement level */ 
	if First.subjnum then Entry="FirstEntry"; 
	if Last.subjnum then Entry="LastEntry"; 
	if Last.subjnum and First.subjnum  then Entry="OnlyBase"; 
run; 
 
/* We don't need the entries with only baseline visit */ 
proc sql; 
delete from child_sample_part5 where Entry="OnlyBase"; 
quit; 
 
proc print data=child_sample_part5; 
run; 
 
%MACRO Ttest_baseToLastKnown(dataset,var,level); 
title "t-Test for &var between Base and Last Known Assessment"; 
proc ttest data= &dataset; 
class &level; 
var &var; 
run; 
%MEND Ttest_baseToLastKnown; 
 
/* Call to each sdq against gender */ 
%Ttest_baseToLastKnown(child_sample_part5, sdq_ess, Entry); 
%Ttest_baseToLastKnown(child_sample_part5, sdq_cps, Entry); 
%Ttest_baseToLastKnown(child_sample_part5, sdq_iha, Entry); 
%Ttest_baseToLastKnown(child_sample_part5, sdq_pps, Entry); 
%Ttest_baseToLastKnown(child_sample_part5, sdq_psb, Entry); 
 
%MEND ExecuteSASprograms; 
 
/* Main execution for questions starts from here , create the child_sample first in the beginning of the script */ 
%ExecuteSASprograms(child_sample, SubjGender); 