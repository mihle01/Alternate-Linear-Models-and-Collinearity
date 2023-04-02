libname HW8 "/home/u60739998/BS 805/Class 8";
filename dehydr "/home/u60739998/BS 805/Class 8/dehydration_f22.xlsx";

proc import datafile=dehydr
	out=dehydration
	dbms=xlsx
	replace;
run;
	
/* assessing potential colinearity of age and weight; do we need both? */
proc reg data=dehydration;
	model rehydration_score=dose age weight / tol vif collinoint; *Model A, collinoint adjusts intercept out of diagnostic;
	model rehydration_score=dose age / tol vif collinoint; *Model B;
	model rehydration_score=dose weight / tol vif collinoint; *Model C;
run;

/* creating piecewise variables */
data dehydration_piecewise;
	set dehydration;
	
	if (0 <= dose < 1) then dose1=dose;
	else if dose >= 1 then dose1=1;
	
	if (0 <= dose < 1) then dose2=1;
	else if (1 <= dose < 2) then dose2=dose;
	else if dose >=2 then dose2=2;
	
	if (0 <= dose < 2) then dose3=2;
	else if dose >= 2 then dose3=dose;
	
	if (0 <= dose < 1) then dosegroup=1;
	else if (1 <= dose < 2) then dosegroup=2;
	else if dose >= 2 then dosegroup=3;
run;

proc sort data=dehydration_piecewise;
	by dose;
run;
/* see if variables were created correctly */
proc sgplot data=dehydration_piecewise;
	series x=dose y=dose1;
	series x=dose y=dose2;
	series x=dose y=dose3;
run; 

proc glm data=dehydration_piecewise;
	class dosegroup;
	model rehydration_score=dosegroup;
	means dosegroup;
	means dosegroup / tukey cldiff;
run;

proc reg data=dehydration;
	model rehydration_score=dose;
	output out=stats1 p=predicted;
run;

proc reg data=dehydration_piecewise;
	model rehydration_score=dose1 dose2 dose3 / stb;
	output out=stats2 p=rehydr_pred;
	test dose1=dose2;
	test dose2=dose3;
run;

proc sort data=stats1;
	by id;
run;

proc sort data=stats2;
	by id;
run;
/* merging datasets that contain the two different predicted values for simple and piecewise linear reg */
data merged;
	merge stats1 stats2;
	by id;
run;

proc sort data=merged;
	by dose;
run;
/* one plot that compares piecewise to simple linear regression */
proc sgplot data=merged;
	scatter x=dose y=rehydration_score;
	series x=dose y=predicted / legendlabel = "Predicted values rehydration_score (simple linear model)"; *simple linear regression;
	series x=dose y=rehydr_pred / legendlabel = "Predicted values rehydration_score (piecewise model)" lineattrs= (color=purple pattern=dash); *piecewise;
run;