clear
clear matrix
clear mata
capture log close
set more off, perm
numlabel, add

*******************************************************************************
*
*	FILENAME:	MHCC_BayerPatientAnalysis_$date_initials.do
*	PURPOSE:	Analyze MHCC patient data for Bayer family planning quality metrics
*			 	analysis
*	DATA IN: 	patient.dta
*	DATA OUT:	
*	UPDATES: SG updates Oct 2017 for updated data that incorporated facility and provider characeristics
*
*******************************************************************************

*******************************************************************************
* SET MACROS AND READ IN DATA
*******************************************************************************

* Set directories
global datadir "\\win.ad.jhu.edu\cloud\sddesktop$\CPHIT_FamilyPlanningResearch\derived_data"
global resultsdir "\\win.ad.jhu.edu\cloud\sddesktop$\CPHIT_FamilyPlanningResearch\Results"
cd "$datadir"

* Create log
log using "logs\MHCC_BayerPatientAnalysis_full_$S_DATE.log", replace

*describe using "$datadir/patient.dta"


* Read in patients .dta file

use patient_id age_dec2014 sex zip2013 zip2014 monthly_enrollment_2013 monthly_enrollment_2014 ///
monthly_pharmacy_enrollment_2013 monthly_pharmacy_enrollment_2014 covtype ///
geo_patcounty geo_patstate geo_patzip5 y2013_mpp_npi y2013_mpp_grouping ///
y2013_mpp_classification y2014_mpp_npi y2014_mpp_grouping y2014_mpp_classification ///
abortion ami asthma autoimmune coc_pill copper_iud_inserted copper_iud_insertion ///
copper_iud_reinserted copper_iud_reinsertion cv_disease cv_risk delivery ///
delivery_imputed diaphragm ectopic_pregnancy emergency_contraception hormonal_iud_inserted ///
hormonal_iud_insertion hormonal_iud_reinserted hormonal_iud_reinsertion ///
htn hx_tobacco_use hysterectomy implant_inserted implant_inserted_imputed ///
implant_insertion implant_reinserted implant_reinsertion implant_removal ///
induced_abortion injection iud_inserted iud_inserted_imputed iud_insertion iud_removal ///
iud_surveillance iud_surveillance_imputed iud_surveillance_without_inser ///
mental_health migraine_with_aura obesity patch pid pop_pill ///
postabortion postabortion_induced postabortion_spontaneous postpartum pregnant ///
pulmonary_embolism ring smoking spontaneous_abortion sterilization stroke vte ///
anxiety depression diabetes using "$datadir/patient.dta", clear



***SUBSET 1% sample for cleaning***
* Read in patients .dta file
*use "$datadir/patient.dta", clear
/*
use patient_id age_dec2014 sex zip2013 zip2014 monthly_enrollment_2013 monthly_enrollment_2014 ///
monthly_pharmacy_enrollment_2013 monthly_pharmacy_enrollment_2014 covtype ///
geo_patcounty geo_patstate geo_patzip5 y2013_mpp_npi y2013_mpp_grouping ///
y2013_mpp_classification y2014_mpp_npi y2014_mpp_grouping y2014_mpp_classification ///
abortion ami asthma autoimmune coc_pill copper_iud_inserted copper_iud_insertion ///
copper_iud_reinserted copper_iud_reinsertion cv_disease cv_risk delivery ///
delivery_imputed diaphragm ectopic_pregnancy emergency_contraception hormonal_iud_inserted ///
hormonal_iud_insertion hormonal_iud_reinserted hormonal_iud_reinsertion ///
htn hx_tobacco_use hysterectomy implant_inserted implant_inserted_imputed ///
implant_insertion implant_reinserted implant_reinsertion implant_removal ///
induced_abortion injection iud_inserted iud_inserted_imputed iud_insertion iud_removal ///
iud_surveillance iud_surveillance_imputed iud_surveillance_without_inser ///
mental_health migraine_with_aura obesity patch pid pop_pill ///
postabortion postabortion_induced postabortion_spontaneous postpartum pregnant ///
pulmonary_embolism ring smoking spontaneous_abortion sterilization stroke vte ///
anxiety depression diabetes if inrange(runiform(),0,.01) using "$datadir/patient.dta", clear
*/



*******************************************************************************
* CLEAN UP PROVIDER VARIABLES
*******************************************************************************

save "$datadir/patient_analysis.dta", replace





*******************************************************************************
* GENERATE AND RECODE VARIABLES
*******************************************************************************

* Rename age variable
rename age_dec2014 age_14

* Generate age in 2013 variables
gen age_13=age_14-1
lab var age_13 "Age in December 2013"
lab var age_14 "Age in December 2014"

* Generate 5-year age categorical variable
egen age5_13=cut(age_13), at(15(5)45) icodes
egen age5_14=cut(age_14), at(15(5)45) icodes
lab def age5_list 0 "15-19" 1 "20-24" 2 "25-29" 3 "30-34" 4 "35-39" 5 "40-44" 
lab val age5_14 age5_13 age5_list

* Rename monthly enrollment variables
rename monthly_enrollment_2013 mo_enroll_13
rename monthly_enrollment_2014 mo_enroll_14
rename monthly_pharmacy_enrollment_2013 mo_pharm_13
rename monthly_pharmacy_enrollment_2014 mo_pharm_14

* Generate an ineligible variable by year
gen ineligible_13=.
gen ineligible_14=.
replace ineligible_13=1 if age_13==14
replace ineligible_14=1 if age_14==45

* Generate eligible variable by year
foreach x of numlist 3/4 {
	gen eligible_1`x'=regexm(mo_enroll_1`x', "111111")
	replace eligible_1`x'=0 if age_1`x'<15
	replace eligible_1`x'=0 if age_1`x'>44
	lab var eligible_1`x' "Eligible in 201`x'"
}

replace ineligible_13=2 if eligible_13==0 & ineligible_13==.
replace ineligible_14=2 if eligible_14==0 & ineligible_14==.

* Generate dichotomous month variables for enrollment variables
foreach var in mo_enroll_13 mo_enroll_14 mo_pharm_13 mo_pharm_14 {
foreach num of numlist 1/12 {
gen `var'_`num'=substr(`var',`num',1)
destring `var'_`num', replace
}
}

* Generate dichotomous month variables for combine enrollment and pharm coverage variables
foreach y of numlist 3/4 {
foreach x of numlist 1/12 {
gen mo_ep_1`y'_`x'=1 if mo_enroll_1`y'_`x'==1 & mo_pharm_1`y'_`x'==1
}
}

* Sum number of months enrolled
foreach x of numlist 3/4 {
	egen mo_e_1`x'_sum_id=rowtotal(mo_enroll_1`x'_1-mo_enroll_1`x'_12)
	lab var mo_e_1`x'_sum_id "Total number of months enrolled in 201`x' for each patient"
}

* Sum number of month enrolled and with pharm coverage
foreach x of numlist 3/4 {
	egen mo_ep_1`x'_sum_id=rowtotal(mo_ep_1`x'_1-mo_ep_1`x'_12)
	lab var mo_ep_1`x'_sum_id "Total number of months enrolled with pharmacy coverage in 201`x' for each patient"
}


**ADD IN AT RISK VARIABLE HERE**
* Create ineligible (not at risk of pregnancy) months variables due to hysterectomy or pregnancy
*hyst

gen hyst_1=substr(hysterectomy,1,1)
destring hyst_1, replace
foreach num of numlist 2/60 {
	gen hyst_`num'=substr(hysterectomy,`num',1)
	destring hyst_`num', replace
	local x = `num'-1
	replace hyst_`num'=1 if hyst_`num'==0 & hyst_`x'==1
	}

*pregnant
foreach num of numlist 37/60 {
	gen preg_`num'=substr(pregnant,`num',1)
	destring preg_`num', replace
	}
	
*generate set of atrisk = at risk monthly variables
foreach num of numlist 37/60 {
	gen atrisk_`num'=1
	replace atrisk_`num'=0 if preg_`num'==1 | hyst_`num'==1
}
local x = 0
foreach num of numlist 37/48 {
	local ++x
	rename atrisk_`num' atrisk_13_`x'
	}
local x = 0
foreach num of numlist 49/60 {
	local ++x
	rename atrisk_`num' atrisk_14_`x'
}

/*
*generate set of atriske = at risk monthly variables during enrolled months
foreach x of numlist 3/4 {
foreach y of numlist 1/12 {
	gen atriske_1`x'_`y'=atrisk_1`x'_`y'
	replace atriske_1`x'_`y' = 0 if mo_enroll_1`x'_`y'==0
	}
}
*/

*generate set of atriskp = at risk monthly variables during enrolled months with pharmacy coverage
foreach x of numlist 3/4 {
foreach y of numlist 1/12 {
	gen atriskp_1`x'_`y'=1
	replace atriskp_1`x'_`y' = 0 if mo_ep_1`x'_`y'==.
	replace atriskp_1`x'_`y'=0 if atrisk_1`x'_`y'==0
	}
}


label define ineligible 1 "age <15" 2 "<60mo continuous enrl" 3 "no at risk pharm months"
label val ineligible_13 ineligible
label val ineligible_14 ineligible
tab1 ineligible_13 ineligible_14, miss


/*	
* Sum number of months enrolled and at risk (are)
foreach x of numlist 3/4 {
	egen mo_are_1`x'_sum_id=rowtotal(atrisk_1`x'_1-atriske_1`x'_12)
	lab var mo_ere_1`x'_sum_id "Total number of months enrolled and at risk in 201`x' for each patient"
}
*/

* Sum number of month enrolled and with pharm coverage and at risk
foreach x of numlist 3/4 {
	egen mo_arep_1`x'_sum_id=rowtotal(atriskp_1`x'_1-atriskp_1`x'_12)
	lab var mo_arep_1`x'_sum_id "Total number of months enrolled with pharmacy and at risk in 201`x' for each patient"
}

* Update eligible variables to exclude women never at risk of pregnancy with pharm coverage
foreach x of numlist 3/4 {
	replace eligible_1`x'=0 if mo_arep_1`x'_sum_id==0 | mo_arep_1`x'_sum_id==.
	}

	
replace ineligible_13=3 if eligible_13==0 & ineligible_13==.
replace ineligible_14=3 if eligible_14==0 & ineligible_14==.

tab1 ineligible_13 ineligible_14, miss	

*tab mo_ep_13_sum_id if ineligible_13==3
replace ineligible_13=4 if ineligible_13==3 & mo_ep_13_sum_id!=0
replace ineligible_14=4 if ineligible_14==3 & mo_ep_14_sum_id!=0
label define ineligible 1 "age <15 or >44" 2 "<6mo continuous enrl" 3 "never pharmacy coverage" 4 "never at risk of pregnancy", modify
tab1 ineligible_13 ineligible_14, miss	

	
*save "$datadir/temp3.dta", replace	
*use "$datadir/temp3.dta", clear


* Rename variables
rename copper_iud_inserted cop_iud
rename copper_iud_insertion cop_iud_insert
rename copper_iud_reinserted cop_iud_re
rename ectopic_pregnancy ectopic
rename emergency_contraception ec
rename hormonal_iud_inserted horm_iud
rename hormonal_iud_insertion horm_iud_insert
rename hormonal_iud_reinserted horm_iud_re
rename hormonal_iud_reinsertion horm_iud_reinsert
rename hysterectomy hyst
rename hx_tobacco_use hx_tobac
rename injection inject
rename implant_inserted implant
rename implant_insertion implant_insert
rename implant_reinserted implant_re
rename implant_reinsertion implant_reinsert
rename implant_removal implant_removal
rename implant_inserted_imputed implant_im
rename iud_inserted iud
rename iud_insertion iud_insert
rename iud_removal iud_removal
rename iud_surveillance iud_surv
rename iud_inserted_imputed iud_im
rename iud_surveillance_imputed iud_sim
rename mental_health mental
rename migraine_with_aura migrain
rename pulmonary_embolism pul_emb
rename sterilization ster

* Generate dichotomous month variables for health conditions and contraception
foreach var in implant implant_re implant_im horm_iud horm_iud_re cop_iud cop_iud_re ec ///
	coc_pill pop_pill ring patch inject diaphragm iud iud_im iud_sim {
foreach num of numlist 37/60 {
gen `var'_`num'=substr(`var',`num',1)
destring `var'_`num', replace
}
}

* Generate dichotomous month variables for sterilization, carried forward
gen ster_1=substr(ster,1,1)
destring ster_1, replace
foreach num of numlist 2/60 {
	gen ster_`num'=substr(ster,`num',1)
	destring ster_`num', replace
	local x = `num'-1
	replace ster_`num'=1 if ster_`num'==0 & ster_`x'==1
	}

*Generate combined monthly variables for implant, hormonal iud, copper iud, and unknown iud


foreach var in implant_c horm_iud_c cop_iud_c iud_c {
	foreach num of numlist 37/60 {
		gen `var'_`num'=0
		}
	}

foreach var in implant implant_re implant_im {
	foreach num of numlist 37/60 {
		replace implant_c_`num'=1 if `var'_`num'==1
		}
	}

foreach var in horm_iud horm_iud_re {
	foreach num of numlist 37/60 {
		replace horm_iud_c_`num'=1 if `var'_`num'==1
		}
	}

foreach var in cop_iud cop_iud_re {
	foreach num of numlist 37/60 {
		replace cop_iud_c_`num'=1 if `var'_`num'==1
		}
	}

foreach var in iud iud_im iud_sim {
	foreach num of numlist 37/60 {
		replace iud_c_`num'=1 if `var'_`num'==1
		replace iud_c_`num'=0 if cop_iud_c_`num'==1
		replace iud_c_`num'=0 if horm_iud_c_`num'==1
		}
	}



	
save "$datadir/temp2.dta", replace	
use "$datadir/temp2.dta", clear
set more off
*Generate combined monthly variables for LARC
	foreach num of numlist 37/60 {
		gen larc_`num'=0
			foreach var in implant_c horm_iud_c cop_iud_c iud_c {
			replace larc_`num'=1 if `var'_`num'==1
		}
	}

*Generate combined monthly variables for combined IUDs
	foreach num of numlist 37/60 {
		gen iudall_`num'=0
			foreach var in horm_iud_c cop_iud_c iud_c {
			replace iudall_`num'=1 if `var'_`num'==1
		}
	}
	
	
*Generate combined monthly variables for non-LARC
	foreach num of numlist 37/60 {
		gen nonlarc_`num'=0
			foreach var in ec coc_pill pop_pill ring patch inject diaphragm  {
			replace nonlarc_`num'=1 if `var'_`num'==1
			replace nonlarc_`num'=0 if larc_`num'==1
		}
	}
*Generate combined monthly variables for any method
	foreach num of numlist 37/60 {
		gen any_`num'=0
			foreach var in larc nonlarc  {
			replace any_`num'=1 if `var'_`num'==1
		}
	}

*Generate combined monthly variables for any method AND sterilization
	foreach num of numlist 37/60 {
		gen anyst_`num'=0
			foreach var in any ster  {
			replace anyst_`num'=1 if `var'_`num'==1
		}
	}

* Sum person-months across months for 2013 and 2014 among enrolled at risk months with pharmacy coverage

foreach var in implant_c cop_iud_c horm_iud_c iud_c ec coc_pill pop_pill ring patch inject diaphragm larc iudall nonlarc any anyst {
	local y = 0
	foreach x of numlist 37/48 {
		local ++y
		replace `var'_`x'=. if atriskp_13_`y'==0
		}
	egen `var'_ep13_sum_id=rowtotal(`var'_37-`var'_48)
	}
	
foreach var in implant_c cop_iud_c horm_iud_c iud_c ec coc_pill pop_pill ring patch inject diaphragm  larc iudall nonlarc any anyst {
	local y = 0
	foreach x of numlist 49/60 {
		local ++y
		replace `var'_`x'=. if atriskp_14_`y'==0
		}
	egen `var'_ep14_sum_id = rowtotal(`var'_49-`var'_60)
	}


save "$datadir/temp6.dta", replace	
*use "$datadir/temp6.dta", clear	

* Generate dichotomous variable for whether used any method or LARC ever or for or 12 months by year
foreach var in anyst any larc {
	foreach mo of numlist 1 12 {
		foreach yr of numlist 3/4 {
			gen `var'_`mo'mo_ep1`yr'_sum_id=0 if eligible_1`yr'==1 & (mo_arep_1`yr'_sum_id>=`mo' & mo_arep_1`yr'_sum_id!=.)
			replace `var'_`mo'mo_ep1`yr'_sum_id=1 if `var'_ep1`yr'_sum_id>=`mo' & `var'_`mo'mo_ep1`yr'_sum_id!=.
			
			}
		}
	}

	

compress
save "$datadir/temp7.dta", replace

use "$datadir/temp7.dta", clear

drop anxiety depression diabetes
preserve
	use patient_id anxiety depression diabetes using "$datadir/patient.dta", clear
	save "$datadir/newvars_merge.dta", replace
restore
merge 1:1 patient_id using "$datadir/newvars_merge.dta", nogen
save "$datadir/temp7a.dta", replace
set more off


* Generate dichotomous variables for each health condition by year 
foreach var in obesity htn smoking cv_disease cv_risk vte asthma {
	gen `var'_13=substr(`var',1,48)
	gen `var'_ever14=regexm(`var',"1")
	gen `var'_ever13=regexm(`var'_13,"1")
	}

set more off
foreach var in autoimmune mental anxiety depression diabetes {
	gen `var'_13=substr(`var',1,48)
	gen `var'_ever14=regexm(`var',"1")
	gen `var'_ever13=regexm(`var'_13,"1")
	}


* Generate more conservative dichotomous PID variable by year
gen pid_only13=substr(pid,37,12)
gen pid_only14=substr(pid,49,12)
gen pid_ever13=regexm(pid_only13,"1")
gen pid_ever14=regexm(pid_only14,"1")

* Generate diagnoses tobacco use dichotmous variable

foreach var in hx_tobac {
	gen `var'_13=substr(`var',1,48)
	gen `var'_ever14=regexm(`var',"1")
	gen `var'_ever13=regexm(`var'_13,"1")
	}


* Combine smoking variables
gen smoker_ever13=0 if smoking_ever13!=.
replace smoker_ever13=1 if smoking_ever13==1
replace smoker_ever13=1 if hx_tobac_ever13==1

gen smoker_ever14=0 if smoking_ever14!=.
replace smoker_ever14=1 if smoking_ever14==1
replace smoker_ever14=1 if hx_tobac_ever14==1

*save "$datadir/temp8.dta", replace

* Label and destring coverage type variable
replace covtype="10" if covtype=="A"
replace covtype="11" if covtype=="B"
replace covtype="12" if covtype=="C"
replace covtype="13" if covtype=="Z"
destring covtype, replace
lab def covtype_list 1 "Medicare Supplement" 2 "Medicare Advantage Plan"	///
3 "Individual Market (not MHIP)" 4 "Maryland Health Insurance (MHIP)"	///
5 "Private Employer Sponsored or Other Group" 6 "Public Employee - Federal (FEHBP)"	///
7 "Public Employee - Other" 8 "Comprehensive Standard Health Benefit Plan (except HIP)"	///
9 "Health Insurance Partnership" 10 "Student Health Plan" 11 "Individual Market - sold in MHBE"	///
12 "Small Business Options Program (SHOP) - sold in MHBE" 13 "Unknown"
lab val covtype covtype_list

* Generate recode of coverage type
recode covtype (5=1 "Private Employer Sponsored or Other Group") (6=2 "Public Employee - Federal (FEHBP)")	///
(7=3 "Public Employee - Other") (12=4 "Small Business Options Program") (8=5 "Comprehensive Standard Health Benefit Plan (except HIP)")	///
(3=6 "Individual Market (not MHIP)") (11=7 "Individual Market - sold in MHBE") (1 2 4 9 10 13=8 "Other"), gen(covtypev2)

*save "$datadir/temp9.dta", replace

*Add abortions variable
gen abortion_s13=substr(abortion,37,12)
gen abortion_s14=substr(abortion,49,12)
gen abortion_13=regexm(abortion_s13,"1")
gen abortion_14=regexm(abortion_s14,"1")

*Add delivery variable
gen delivery_s13=substr(delivery,37,12)
gen delivery_s14=substr(delivery,49,12)
gen delivery_13=regexm(delivery_s13,"1")
gen delivery_14=regexm(delivery_s14,"1")



*Create facility variables for woman level analysis
*first use modal facility if available, then 
/*
gen provider_id=""
foreach v in iud_inserted iud_inserted_i iud_surv_i ciud_inserted ciud_reinserted ///
	hiud_inserted hiud_reinserted implant_inserted imp_reinserted imp_inserted_i ///
	injection coc_pill pop_pill patch ring diaphragm ec {
	replace provider_id=`v'_initobs_facnpi if provider_id==""
	replace provider_id=`v'_initobs_npi if provider_id==""
	replace provider_id=`v'_mostobs_facnpi if provider_id==""
	replace provider_id=`v'_mostobs_npi if provider_id==""
	}
gen factype=""
foreach v in iud_inserted iud_inserted_i iud_surv_i ciud_inserted ciud_reinserted ///
	hiud_inserted hiud_reinserted implant_inserted imp_reinserted imp_inserted_i ///
	injection coc_pill pop_pill patch ring diaphragm ec {
	replace factype=`v'_initobs_factype if factype==""
	replace factype=`v'_mostobs_factype if factype==""
	replace factype=`v'_initall_factype if factype==""
	}
destring factype, replace
*/

*Provider group identifier == y201x_mpp_npi
*clean grouping


capture drop y2014_mpp_size
capture drop y2014_counter
bys y2014_mpp_npi eligible_14: egen y2014_mpp_size=count(y2014_mpp_npi)
bys y2014_mpp_npi eligible_14: gen y2014_counter=_n

save "$datadir/patient_complete_analytic.dta", replace



use "$datadir/patient_complete_analytic.dta", clear

tab1 y2013_mpp_gr 
tab y2013_mpp_cl if strpos(y2013_mpp_gr, "Physicians")>1 & eligible_13==1
tab y2013_mpp_cl if strpos(y2013_mpp_gr, "Advanced Practice")>1 & eligible_13==1

label define mpp_gr 1 "Physicians" 2 "PAs and APCs" 3 "Ambulatory" 4 "Behavioral" 5 "All others", modify
label define mpp_cl 1 "Family Med" 2 "Internal Med" 3 "Obgyn" 4 "Peds" 5 "NP" 6 "Clinic" 7 "All others", modify
foreach y of numlist 3/4 {
	gen y201`y'_mpp_gr=.
	replace y201`y'_mpp_gr=1 if y201`y'_mpp_grouping=="Allopathic & Osteopathic Physicians"
	replace y201`y'_mpp_gr=2 if y201`y'_mpp_grouping=="Physician Assistants & Advanced Practice Nursing Providers"
	replace y201`y'_mpp_gr=3 if y201`y'_mpp_grouping=="Ambulatory Health Care Facilities"
	replace y201`y'_mpp_gr=4 if y201`y'_mpp_grouping=="Behavioral Health & Social Service Providers"
	replace y201`y'_mpp_gr=5 if y201`y'_mpp_gr==. & y201`y'_mpp_grouping!=""
	label val y201`y'_mpp_gr mpp_gr
	gen y201`y'_mpp_cl=.
	replace y201`y'_mpp_cl=1 if y201`y'_mpp_classification=="Family Medicine"
	replace y201`y'_mpp_cl=2 if y201`y'_mpp_classification=="Internal Medicine"
	replace y201`y'_mpp_cl=3 if y201`y'_mpp_classification=="Obstetrics & Gynecology"
	replace y201`y'_mpp_cl=4 if y201`y'_mpp_classification=="Pediatrics"
	replace y201`y'_mpp_cl=5 if y201`y'_mpp_classification=="Nurse Practitioner"
	replace y201`y'_mpp_cl=6 if y201`y'_mpp_classification=="Clinic/Center"
	replace y201`y'_mpp_cl=7 if y201`y'_mpp_cl==. & y201`y'_mpp_classification!=""
	label val y201`y'_mpp_cl mpp_cl
	}

*combined approach
label define mppc 1 "Phys-Fam Med" 2 "Phys-Internal Med" 3 "Phys-Obgyn" ///
	4 "Phys-Peds" 5 "Phys-Others" 6 "APC-NP" 7 "APC-Adv Pract Midwife" ///
	8 "APC-PA" 9 "APC-Others" 10 "Facilities and other providers"
foreach y of numlist 3/4 {
	capture drop y201`y'_mppc
	gen y201`y'_mppc=.
	replace y201`y'_mppc=1 if y201`y'_mpp_grouping=="Allopathic & Osteopathic Physicians" & ///
		(y201`y'_mpp_classification=="Family Medicine" | y201`y'_mpp_classification=="General Practice" | ///
		y201`y'_mpp_classification=="Preventive Medicine")
	replace y201`y'_mppc=2 if y201`y'_mpp_grouping=="Allopathic & Osteopathic Physicians" & y201`y'_mpp_classification=="Internal Medicine"
	replace y201`y'_mppc=3 if y201`y'_mpp_grouping=="Allopathic & Osteopathic Physicians" & y201`y'_mpp_classification=="Obstetrics & Gynecology"
	replace y201`y'_mppc=4 if y201`y'_mpp_grouping=="Allopathic & Osteopathic Physicians" & y201`y'_mpp_classification=="Pediatrics"
	replace y201`y'_mppc=5 if y201`y'_mpp_grouping=="Allopathic & Osteopathic Physicians" & y201`y'_mppc==.
	replace y201`y'_mppc=6 if strpos(y201`y'_mpp_grouping, "Advanced Practice")>1 & y201`y'_mpp_classification=="Nurse Practitioner"
	replace y201`y'_mppc=7 if strpos(y201`y'_mpp_grouping, "Advanced Practice")>1 & y201`y'_mpp_classification=="Advanced Practice Midwife"
	replace y201`y'_mppc=8 if strpos(y201`y'_mpp_grouping, "Advanced Practice")>1 & y201`y'_mpp_classification=="Physician Assistant"
	replace y201`y'_mppc=9 if strpos(y201`y'_mpp_grouping, "Advanced Practice")>1 & y201`y'_mppc==.
	replace y201`y'_mppc=10 if y201`y'_mpp_grouping!="" & y201`y'_mppc==.
	label val y201`y'_mppc mppc
	}

*Categorized/collapsed list
tab y2013_mppc if eligible_13==1, miss
tab y2014_mppc if eligible_14==1, miss

*Full list (for appendix)
tab y2013_mpp_classification if y2013_mppc==5 & eligible_13==1
tab y2013_mpp_classification if y2013_mppc==9 & eligible_13==1
tab y2013_mpp_classification if y2013_mppc==10 & eligible_13==1

tab y2014_mpp_classification if y2014_mppc==5 & eligible_14==1
tab y2014_mpp_classification if y2014_mppc==9 & eligible_14==1
tab y2014_mpp_classification if y2014_mppc==10 & eligible_14==1
	
	
	
*code rurality variable using RUCAs
destring zip2013 zip2014, replace force
*save "$datadir/patient_complete_analytic2pct_temp.dta", replace
/*
preserve
import excel "S:\CPHIT_FamilyPlanningResearch\derived_data\ruca2_MD.xls", sheet("Sheet1") firstrow clear
codebook ZIPN
codebook RUCA2
keep ZIPN RUCA2
rename ZIPN zip2013
rename RUCA2 ruca2013
	

recode ruca2013 (1 1.1 2 2.1 3 4.1 5.1 7.1 8.1 10.1 = 1) ///
	(4 4.2 5.0 5.2 6.0 6.1 = 2) (7 7.2 7.3 7.4 8 8.2 8.3 8.4 9 9.1 9.2 = 3) ///
	(10 10.2 10.3 10.4 10.5 10.6 = 4), gen(rucaa2013)
label define rucaa 1 "Urban" 2 "Large Rural City/Town" ///
	3 "Small Rural Town" 4 "Isolated Small Rural Town"
label val rucaa2013 rucaa
tab ruca2013 rucaa2013, miss

recode rucaa2013 (4 = 3), gen(rucab2013)
label define rucab 1 "Urban" 2 "Large Rural City/Town" ///
	3 "Small and Isolated Small Rural Town"
label val rucab2013 rucab
tab rucab2013 rucaa2013, miss	

recode rucab2013 (3 = 2), gen(rucac2013)
label define rucac 1 "Urban" 2 "Rural"
label val rucac2013 rucac
tab rucab2013 rucac2013, miss	
	
save "$datadir/ruca2013.dta", replace
rename *3 *4
save "$datadir/ruca2014.dta", replace
restore
*use "$datadir/patient_complete_analytic2pct_temp.dta", clear
*/

*economize 
drop abortion-cop_iud 
drop cop_iud_insert-vte
drop mo_enroll_13-geo_patzip5
drop *_s13 *_s14
compress


merge m:1 zip2013 using "$datadir/ruca2013.dta", nogen
merge m:1 zip2014 using "$datadir/ruca2014.dta", nogen
drop if age_14==.
capture log close


*explore zip codes
set more off
* Generate zip code groups
capture drop zipg_13
capture drop zipg_14

egen zipg_13=cut(zip2013), at(0(10000)100000) icodes
egen zipg_14=cut(zip2014), at(0(10000)100000) icodes
tab1 zipg_13 if eligible_13==1, miss
tab1 zipg_14 if eligible_14==1, miss

gen zcta5=zip2013
/*
use "$datadir/zip_state.dta", clear
destring(zcta5), replace
sort zcta5 pop10
by zcta5: gen junk0=_n
drop if junk0>1
codebook zcta5
drop if zcta5==99999
save "$datadir/zip_state_merge.dta", replace
*/
capture drop _merge
merge m:1 zcta5 using "$datadir/zip_state_merge.dta", keepusing(stab) keep(match master)
tab1 stab if eligible_13==1, miss
rename stab stab_13
drop zcta5
gen zcta5=zip2014
capture drop _merge
merge m:1 zcta5 using "$datadir/zip_state_merge.dta", keepusing(stab) keep(match master)
tab1 stab if eligible_14==1, miss
rename stab stab_14
drop zcta5

gen rucas2013 = rucac2013
replace rucas2013 = 3 if rucac2013==. & stab_13!="MD" & stab_13!=""
gen rucas2014 = rucac2014
replace rucas2014 = 3 if rucac2014==. & stab_14!="MD" & stab_14!=""

label define rucas 1 "urban" 2 "rural" 3 "out of state"
label val rucas2013 rucas
label val rucas2014 rucas

tab rucas2013 if eligible_13==1, miss
tab rucas2014 if eligible_14==1, miss

/*
*prep mediam household income by zip code data for merging
clear
import excel "S:\CPHIT_FamilyPlanningResearch\derived_data\MedianZIP-3.xlsx", sheet("Median") cellrange(A1:B32635) firstrow case(lower)
gen zip2013=zip
gen zip2014=zip
gen hhinc2013=median
gen hhinc2014=median
drop median zip
save "median_hh_income_by_zip_to_merge.dta", replace
*/

*code median household income variables
capture drop _merge
merge m:1 zip2013 using median_hh_income_by_zip_to_merge, keepus(hhinc2013)
drop if _merge==2
codebook hhinc2013 if eligible_13==1

capture drop _merge
merge m:1 zip2014 using median_hh_income_by_zip_to_merge, keepus(hhinc2014)
drop if _merge==2
codebook hhinc2014 if eligible_14==1

replace hhinc2013=. if eligible_13!=1
replace hhinc2014=. if eligible_14!=1

sum hhinc2013 if eligible_13==1
histogram hhinc2013 if eligible_13==1
tabstat hhinc2013 if eligible_13==1, s(min p25 p50 p75 max)

xtile hhinc2013_5 = hhinc2013, nq(5)
xtile hhinc2014_5 = hhinc2014, nq(5)


*Code variable for multiple conditions:
capture drop nconditions_14
gen nconditions_14=0
foreach v of varlist cv_disease_ever14 htn_ever14 vte_ever14 obesity_ever14 ///
	asthma_ever14 autoimmune_ever14 depression_ever14 anxiety_ever14 diabetes_ever14 {
	replace nconditions_14=nconditions_14+1 if eligible_14==1 & `v'==1
	}
replace nconditions_14=2 if nconditions_14>1 & nconditions_14!=.
label define nconditions 0 "none/health" 1 "one condition" 2 "more than one"
	label val nconditions_14 nconditions

*Code variables to compare medical conditions to "healthly" cohort
foreach v of varlist cv_disease_ever14 cv_risk_ever14 htn_ever14 vte_ever14 obesity_ever14 ///
	asthma_ever14 autoimmune_ever14 depression_ever14 anxiety_ever14 diabetes_ever14 pid_ever14 {
	capture drop `v'vhc
	gen `v'vhc=.
	replace `v'vhc=1 if `v'==1
	replace `v'vhc=0 if `v'vhc==. & nconditions_14==0
	}

tab	cv_disease_ever14 cv_disease_ever14vhc, miss
	
*code urban/rural/out of state variable


replace eligible_14=0 if age_14>44
save "$datadir/patient_complete_analytic_compressed.dta", replace
/*
use "$datadir/patient_complete_analytic_compressed.dta", clear

*merge back in previous eligible sample variable
use patient_id zip2013 zip2014 monthly_enrollment_2013 monthly_enrollment_2014 ///
	using "$datadir/patient.dta", clear

* Rename monthly enrollment variables
rename monthly_enrollment_2013 mo_enroll_13
rename monthly_enrollment_2014 mo_enroll_14

* Generate eligibleold variable by year
foreach x of numlist 3/4 {
	gen eligibleold_1`x'=regexm(mo_enroll_1`x', "111111")
	lab var eligibleold_1`x' "Eligible in 201`x'"
}
keep patient_id eligibleold*
save "$datadir/patient_eligibleold.dta", replace

use "$datadir/patient_complete_analytic_compressed.dta", clear
drop if patient_id==.
merge 1:1 patient_id using "$datadir/patient_eligibleold.dta", nogen

tab eligibleold_13 eligible_13, miss
tab eligibleold_14 eligible_14, miss
* Rurality (for Maryland residents)
tab rucac2013 if eligibleold_13==1
tab rucac2014 if eligibleold_14==1

save "$datadir/patient_complete_analytic_compressed.dta", replace
*/
use "$datadir/patient_complete_analytic_compressed.dta", clear

set more off
capture log close
log using "logs\MHCC_BayerPatientAnalysis_Complete_TABLES_$S_DATE.log", replace


*generate variable for number of sterilization months in 2014
foreach var in ster {
	local y = 0
	foreach x of numlist 49/60 {
		local ++y
		replace `var'_`x'=. if atriskp_14_`y'==0
		}
	egen `var'_ep14_sum_id = rowtotal(`var'_49-`var'_60)
	}
*generate variable for MMEC for all of 2014
tab anyst_ep14_sum_id if eligible_14==1, miss
tab anyst_ep14_sum_id if eligible_14==1 & anyst_ep14_sum_id!=0, miss
tab anyst_ep14_sum_id if eligible_14==1 & anyst_ep14_sum_id!=0 & larc_12mo_ep14_sum_id!=., miss
tab anyst_ep14_sum_id if eligible_14==1 & anyst_ep14_sum_id!=0 & mo_arep_14_sum_id==12, miss

mo_arep_1`x'_sum_id

/*

**Methods:
*reasons ineligible in 2014
tab eligible_14, miss
tab ineligible_14, miss
*ID women never enrolled in 2014:
egen notenrl_14=rowtotal(mo_enroll_14_1-mo_enroll_14_12)
tab notenrl_14, miss
recode notenrl_14 (0=1) (1/12=0)
tab ineligible_14 notenrl_14, miss

*reverse engineer "total" sample that adds back in those without pharmacy cover, but not those not at risk of pregnancy
*create a new ineligible variable where order of pharmacy/preg exclusion is switched
capture drop _merge
merge 1:1 patient_id using "$datadir\total_pop_to_merge.dta"
egen noriske_14=rowtotal(atriske_14_1-atriske_14_12)
recode noriske_14 (0=1) (1/12=0)

tab ineligible_14 noriske_14, miss

*now put the pieces together
gen ineligible2_14=.
replace ineligible2_14=1 if ineligible_14==1
replace ineligible2_14=2 if ineligible2_14==. & notenrl_14==1
replace ineligible2_14=3 if ineligible2_14==. & ineligible_14==2
replace ineligible2_14=4 if ineligible2_14==. & noriske_14==1

label define ineligible2_ 1 "age <15 or >44" 2 "never enrolled in 2014" 3 "<60mo continuous enrl" ///
	4 "never at risk of preg during enrolled months"
label val ineligible2 ineligible2_
	
tab ineligible_14, miss
tab ineligible2_14, miss
tab ineligible2_14 ineligible_14, miss

gen total_14=.
replace total_14=1 if ineligible2_14==.'
tab1 total_14 eligible_14
tab total_14 eligible_14, miss

*add median household income variable for the total population
capture drop _merge
capture drop hhinc2014
merge m:1 zip2014 using median_hh_income_by_zip_to_merge, keepus(hhinc2014)
drop if _merge==2

replace hhinc2014=. if total_14!=1

xtile hhinc2014tot_5 = hhinc2014, nq(5)




capture log close
log using "logs\MHCC_BayerPatientAnalysis_Complete_TOTAL_TABLES_$S_DATE.log", replace


*******************************************************************************
* TABLE 0. PATIENT CHARACTERISTICS -- TOTAL SAMPLE
*******************************************************************************

* Average age
sum age_14 if total_14==1

* Age
tab age5_14 if total_14==1

* Average months enrolled 
sum mo_e_14_sum_id if total_14==1

* Months enrolled 
tab mo_e_14_sum_id if total_14==1

* Average months enrolled with pharmacy coverage
sum mo_ep_14_sum_id if total_14==1

* Months enrolled with pharmacy coverage
tab mo_ep_14_sum_id if total_14==1

* Coverage type
tab covtypev2 if total_14==1

* Rurality / out of state
tab rucas2014 if total_14==1

* Median household income
tab hhinc2014tot_5 if total_14==1

* Obesity
tab obesity_ever14 if total_14==1

* Smoking
tab smoker_ever14 if total_14==1

* Abortions
tab abortion_14 if total_14==1

* Deliveries
tab delivery_14 if total_14==1


* Cardiovascular disease
tab cv_disease_ever14 if total_14==1

* Cardiovascular risk
tab cv_risk_ever14 if total_14==1

* Diabetes
tab diabetes_ever14 if total_14==1

* Hypertension
tab htn_ever14 if total_14==1

* VTE
tab vte_ever14 if total_14==1

* PID
tab pid_ever14 if total_14==1

*  Asthma
tab asthma_ever14 if total_14==1

* Autoimmune condition
tab autoimmune_ever14 if total_14==1

* Mental Health
tab mental_ever14 if total_14==1

* Anxiety
tab anxiety_ever14 if total_14==1

* Depression
tab depression_ever14 if total_14==1

*Multiple conditions
tab nconditions_14 if total_14==1
 




*******************************************************************************
* TABLE 1. PATIENT CHARACTERISTICS 
*******************************************************************************

* Average age
sum age_13 if eligible_13==1
sum age_14 if eligible_14==1

* Age
tab age5_13 if eligible_13==1
tab age5_14 if eligible_14==1

* Average months enrolled 
sum mo_e_13_sum_id if eligible_13==1
sum mo_e_14_sum_id if eligible_14==1

* Months enrolled 
tab mo_e_13_sum_id if eligible_13==1
tab mo_e_14_sum_id if eligible_14==1

* Average months enrolled with pharmacy coverage
sum mo_ep_13_sum_id if eligible_13==1
sum mo_ep_14_sum_id if eligible_14==1

* Months enrolled with pharmacy coverage
tab mo_ep_13_sum_id if eligible_13==1
tab mo_ep_14_sum_id if eligible_14==1

* Coverage type
tab covtypev2 if eligible_13==1
tab covtypev2 if eligible_14==1

* Rurality / out of state (for Maryland residents)
tab rucas2013 if eligible_13==1
tab rucas2014 if eligible_14==1

* Median household income
tab hhinc2013_5 if eligible_13==1
tab hhinc2014_5 if eligible_14==1

* Obesity
tab obesity_ever13 if eligible_13==1
tab obesity_ever14 if eligible_14==1



* Smoking
tab smoker_ever13 if eligible_13==1
tab smoker_ever14 if eligible_14==1



* Abortions
tab abortion_13 if eligible_13==1
tab abortion_14 if eligible_14==1

* Deliveries
tab delivery_13 if eligible_13==1
tab delivery_14 if eligible_14==1

* Also create by medical conditions?

*******************************************************************************
* TABLE. MEDICAL CONDITIONS 
*******************************************************************************

* Cardiovascular disease
tab cv_disease_ever13 if eligible_13==1
tab cv_disease_ever14 if eligible_14==1

* Cardiovascular risk
tab cv_risk_ever13 if eligible_13==1
tab cv_risk_ever14 if eligible_14==1

* Diabetes
tab diabetes_ever13 if eligible_13==1
tab diabetes_ever14 if eligible_14==1

* Hypertension
tab htn_ever13 if eligible_13==1
tab htn_ever14 if eligible_14==1

* VTE
tab vte_ever13 if eligible_13==1
tab vte_ever14 if eligible_14==1

* PID
tab pid_ever13 if eligible_13==1
tab pid_ever14 if eligible_14==1

*  Asthma
tab asthma_ever13 if eligible_13==1
tab asthma_ever14 if eligible_14==1

* Autoimmune condition
tab autoimmune_ever13 if eligible_13==1
tab autoimmune_ever14 if eligible_14==1

* Mental Health
tab mental_ever13 if eligible_13==1
tab mental_ever14 if eligible_14==1

* Anxiety
tab anxiety_ever13 if eligible_13==1
tab anxiety_ever14 if eligible_14==1

* Depression
tab depression_ever13 if eligible_13==1
tab depression_ever14 if eligible_14==1

*Multiple conditions
tab nconditions_14 if eligible_14==1
 

*******************************************************************************
* TABLE 3. CONTRACEPIVE USE 
*******************************************************************************

* Among eligible patients only in months where enrolled with pharmacy coverage

* Age
	* Any use, including sterilization by age and year
	tabstat anyst_ep13_sum_id if eligible_13==1, by(age5_13) statistics(sum)
	tabstat anyst_ep14_sum_id if eligible_14==1, by(age5_14) statistics(sum)
*/
	* Sterliziation by age and year
	tabstat ster_ep14_sum_id if eligible_14==1, by(age5_14) statistics(sum)
/*
	
	* Any non-LARC use by age and year
	tabstat nonlarc_ep13_sum_id if eligible_13==1, by(age5_13) statistics(sum)
	tabstat nonlarc_ep14_sum_id if eligible_14==1, by(age5_14) statistics(sum)

	* Any LARC use by age and year
	tabstat larc_ep13_sum_id if eligible_13==1, by(age5_13) statistics(sum)
	tabstat larc_ep14_sum_id if eligible_14==1, by(age5_14) statistics(sum)

	* Any IUD use by age and year
	tabstat iudall_ep14_sum_id if eligible_14==1, by(age5_14) statistics(sum)

	* Copper IUD use by age and year
	tabstat cop_iud_c_ep13_sum_id if eligible_13==1, by(age5_13) statistics(sum)
	tabstat cop_iud_c_ep14_sum_id if eligible_14==1, by(age5_14) statistics(sum)

	* Hormonal IUD use by age and year
	tabstat horm_iud_c_ep13_sum_id if eligible_13==1, by(age5_13) statistics(sum)
	tabstat horm_iud_c_ep14_sum_id if eligible_14==1, by(age5_14) statistics(sum)

	* IUD (type undetermined) use by age and year
	tabstat iud_c_ep13_sum_id if eligible_13==1, by(age5_13) statistics(sum)
	tabstat iud_c_ep14_sum_id if eligible_14==1, by(age5_14) statistics(sum)

	* Implant use by age and year
	tabstat implant_c_ep13_sum_id if eligible_13==1, by(age5_13) statistics(sum)
	tabstat implant_c_ep14_sum_id if eligible_14==1, by(age5_14) statistics(sum)

	* Total person-months enrolled by age and year
	tabstat mo_arep_13_sum_id if eligible_13==1, by(age5_13) statistics(sum)
	tabstat mo_arep_14_sum_id if eligible_14==1, by(age5_14) statistics(sum)
	
* Coverage type covtypev2
	* Any use including sterilization by coverage type and year
	tabstat anyst_ep13_sum_id if eligible_13==1, by(covtypev2) statistics(sum)
	tabstat anyst_ep14_sum_id if eligible_14==1, by(covtypev2) statistics(sum)

*/
	* Sterilization by coverage type and year
	tabstat ster_ep14_sum_id if eligible_14==1, by(covtypev2) statistics(sum)
/*

	
	* Any non-LARC use by coverage type and year
	tabstat nonlarc_ep13_sum_id if eligible_13==1, by(covtypev2) statistics(sum)
	tabstat nonlarc_ep14_sum_id if eligible_14==1, by(covtypev2) statistics(sum)

	* Any LARC use by coverage type and year
	tabstat larc_ep13_sum_id if eligible_13==1, by(covtypev2) statistics(sum)
	tabstat larc_ep14_sum_id if eligible_14==1, by(covtypev2) statistics(sum)

	* Any IUD use by coverage type
	tabstat iudall_ep14_sum_id if eligible_14==1, by(covtypev2) statistics(sum)

	* Copper IUD use by coverage type and year
	tabstat cop_iud_c_ep13_sum_id if eligible_13==1, by(covtypev2) statistics(sum)
	tabstat cop_iud_c_ep14_sum_id if eligible_14==1, by(covtypev2) statistics(sum)

	* Hormonal IUD use by coverage type and year
	tabstat horm_iud_c_ep13_sum_id if eligible_13==1, by(covtypev2) statistics(sum)
	tabstat horm_iud_c_ep14_sum_id if eligible_14==1, by(covtypev2) statistics(sum)

	* IUD (type undetermined) use by coverage type and year
	tabstat iud_c_ep13_sum_id if eligible_13==1, by(covtypev2) statistics(sum)
	tabstat iud_c_ep14_sum_id if eligible_14==1, by(covtypev2) statistics(sum)

	* Implant use by coverage type and year
	tabstat implant_c_ep13_sum_id if eligible_13==1, by(covtypev2) statistics(sum)
	tabstat implant_c_ep14_sum_id if eligible_14==1, by(covtypev2) statistics(sum)

	* Total person-months enrolled by coverage type and year
	tabstat mo_arep_13_sum_id if eligible_13==1, by(covtypev2) statistics(sum)
	tabstat mo_arep_14_sum_id if eligible_14==1, by(covtypev2) statistics(sum)
	
* Rurality

foreach me in anyst nonlarc larc iudall implant_c  {
	tabstat `me'_ep14_sum_id if eligible_14==1, by(rucas2014) statistics(sum)
	}

	
	
	*/
foreach me in ster  {
	tabstat `me'_ep14_sum_id if eligible_14==1, by(rucas2014) statistics(sum)
	}
	/*
	
tabstat mo_arep_13_sum_id if eligible_13==1, by(rucas2013) statistics(sum)
tabstat mo_arep_14_sum_id if eligible_14==1, by(rucas2014) statistics(sum)

* Median household income


foreach me in anyst nonlarc larc cop_iud_c horm_iud_c iud_c iudall implant_c  {
	tabstat `me'_ep14_sum_id if eligible_14==1, by(hhinc2014_5) statistics(sum)
	}

	*/
foreach me in ster  {
	tabstat `me'_ep14_sum_id if eligible_14==1, by(hhinc2014_5) statistics(sum)
	}	
	
	/*
	
tabstat mo_arep_14_sum_id if eligible_14==1, by(hhinc2014_5) statistics(sum)
	
	
* Medical conditions
foreach mc in cv_disease_ever cv_risk_ever diabetes_ever htn_ever  obesity_ever vte_ever pid_ever ///
	asthma_ever autoimmune_ever mental_ever depression_ever anxiety_ever nconditions_ {
	foreach me in anyst nonlarc larc iudall implant_c {
		tabstat `me'_ep14_sum_id if eligible_14==1, by(`mc'14) statistics(sum)
		}
		tabstat mo_arep_14_sum_id if eligible_14==1, by(`mc'14) statistics(sum)
	}
*/

foreach mc in cv_disease_ever cv_risk_ever diabetes_ever htn_ever  obesity_ever vte_ever pid_ever ///
	asthma_ever autoimmune_ever mental_ever depression_ever anxiety_ever nconditions_ {
	foreach me in ster {
		tabstat `me'_ep14_sum_id if eligible_14==1, by(`mc'14) statistics(sum)
		}
	}
/*

	
* Total

foreach me in anyst nonlarc larc iudall implant_c {
	tabstat `me'_ep14_sum_id if eligible_14==1, statistics(sum)
	}
	
tabstat mo_arep_14_sum_id if eligible_14==1, statistics(sum)
	


*******************************************************************************
* TABLE 4. WOMAN-LEVEL CONTRACEPTIVE MEASURES
*******************************************************************************

set more off

foreach v in anyst_1mo_ep14_sum_id any_1mo_ep14_sum_id larc_1mo_ep14_sum_id	larc_12mo_ep14_sum_id {	
	*2014
	tab age5_14 `v' if eligible_14==1 , row chi2 nokey
	tab covtypev2 `v' if eligible_14==1 , row chi2 nokey
	tab rucas2014 `v' if eligible_14==1 , row chi2 nokey
	tab hhinc2014_5 `v' if eligible_14==1 , row chi2 nokey
	tab cv_disease_ever14 `v' if eligible_14==1 , row chi2 nokey
	tab cv_risk_ever14 `v' if eligible_14==1 , row chi2 nokey
	tab diabetes_ever14 `v' if eligible_14==1 , row chi2 nokey
	tab htn_ever14 `v' if eligible_14==1 , row chi2 nokey
	tab obesity_ever14 `v' if eligible_14==1 , row chi2 nokey
	tab vte_ever14 `v' if eligible_14==1 , row chi2 nokey
	tab pid_ever14 `v' if eligible_14==1 , row chi2 nokey	
	tab asthma_ever14 `v' if eligible_14==1 , row chi2 nokey
	tab autoimmune_ever14 `v' if eligible_14==1 , row chi2 nokey
	tab depression_ever14 `v' if eligible_14==1 , row chi2 nokey	
	tab anxiety_ever14 `v' if eligible_14==1 , row chi2 nokey	
	tab nconditions_14 `v' if eligible_14==1 , row chi2 nokey
	tab `v'  if eligible_14==1 
	}

	
*******************************************************************************
* TABLE 5. BIVARIABLE MODELS
*******************************************************************************
	
foreach y in anyst_1mo_ep14_sum_id any_1mo_ep14_sum_id larc_1mo_ep14_sum_id larc_12mo_ep14_sum_id {
	logistic `y' b2.age5_14 if  eligible_14==1
	foreach x in age5_14 covtypev2 rucas2014 hhinc2014_5 cv_disease_ever14 cv_risk_ever14 ///
		diabetes_ever14 htn_ever14 obesity_ever14 vte_ever14 pid_ever14 ///
		asthma_ever14 autoimmune_ever14 depression_ever14 anxiety_ever14 nconditions_14 {
		logistic `y' i.`x' if  eligible_14==1
		}
	logistic `y' hhinc2014_5 if  eligible_14==1
	}


capture log close
log using "logs\MHCC_BayerPatientAnalysis_Complete_INTERACTION_TABLES_$S_DATE.log", replace

	
*******************************************************************************
* TABLE 5a. BIVARIABLE MODELS -- interaction by age
*******************************************************************************
	
tab age5_14
tab age5_14, nolab
capture drop age35to44
recode age5_14 (0/3=0) (4/5=1), gen(age35to44)
tab age5_14 age35to44, miss



foreach y in anyst_1mo_ep14_sum_id larc_1mo_ep14_sum_id larc_12mo_ep14_sum_id {
	foreach x in cv_disease_ever14 cv_risk_ever14 ///
		diabetes_ever14 htn_ever14 obesity_ever14 vte_ever14 pid_ever14 ///
		asthma_ever14 autoimmune_ever14 depression_ever14 anxiety_ever14{
		logistic `y' i.`x'##age34to44 if  eligible_14==1
		lincom 1.`x' + 1.`x'#1.age34to44
		}
	logistic `y' i.nconditions_14##age34to44 if  eligible_14==1
	lincom 1.nconditions_14 + 1.nconditions_14#1.age34to44
	lincom 2.nconditions_14 + 2.nconditions_14#1.age34to44
	}
	



*******************************************************************************
* TABLE 5a. BIVARIABLE MODELS versus "healthy" cohort
*******************************************************************************
	
foreach y in anyst_1mo_ep14_sum_id larc_1mo_ep14_sum_id larc_12mo_ep14_sum_id {
	foreach x in cv_disease_ever14 cv_risk_ever14 ///
		diabetes_ever14 htn_ever14 obesity_ever14 vte_ever14 pid_ever14 ///
		asthma_ever14 autoimmune_ever14 depression_ever14 anxiety_ever14 {
		logistic `y' i.`x'vhc if  eligible_14==1
		}
	}
	
*******************************************************************************
* TABLE 6. MULTIVARIABLE MODELS
*******************************************************************************


foreach y in anyst_1mo_ep14_sum_id any_1mo_ep14_sum_id larc_1mo_ep14_sum_id larc_12mo_ep14_sum_id {
	foreach x in cv_disease_ever14 cv_risk_ever14 ///
		diabetes_ever14 htn_ever14 obesity_ever14 vte_ever14 pid_ever14 ///
		asthma_ever14 autoimmune_ever14 depression_ever14 anxiety_ever14 nconditions_14 {
		logistic `y' i.`x' b2.age5_14 i.covtypev2 if  eligible_14==1
		logistic `y' i.`x' b2.age5_14 i.covtypev2 i.rucas2014 hhinc2014_5 if  eligible_14==1
		}
	}

*******************************************************************************
* TABLE 6b. MULTIVARIABLE MODELS versus "healthy" cohort
*******************************************************************************


foreach y in anyst_1mo_ep14_sum_id any_1mo_ep14_sum_id larc_1mo_ep14_sum_id larc_12mo_ep14_sum_id {
	foreach x in cv_disease_ever14 cv_risk_ever14 ///
		diabetes_ever14 htn_ever14 obesity_ever14 vte_ever14 pid_ever14 ///
		asthma_ever14 autoimmune_ever14 depression_ever14 anxiety_ever14 {
		logistic `y' i.`x'vhc b2.age5_14 i.covtypev2 i.rucas2014 hhinc2014_5 if  eligible_14==1
		}
	}
	


*/	
	*******************************************************************************
* TABLE 5a. MULTIVARIABLE MODELS -- interaction by age
*******************************************************************************
	
	
tab age5_14
tab age5_14, nolab
capture drop age35to44
recode age5_14 (0/3=0) (4/5=1), gen(age35to44)
tab age5_14 age35to44, miss


set more off

foreach y in anyst_1mo_ep14_sum_id any_1mo_ep14_sum_id larc_1mo_ep14_sum_id larc_12mo_ep14_sum_id {
	foreach x in cv_disease_ever14 cv_risk_ever14 ///
		diabetes_ever14 htn_ever14 obesity_ever14 vte_ever14 pid_ever14 ///
		asthma_ever14 autoimmune_ever14 depression_ever14 anxiety_ever14{
		logistic `y' i.`x'##age35to44 i.covtypev2 i.rucas2014 hhinc2014_5  if  eligible_14==1
		lincom 1.`x' + 1.`x'#1.age35to44
		}
	logistic `y' i.nconditions_14##age35to44 i.covtypev2 i.rucas2014 hhinc2014_5  if  eligible_14==1
	lincom 1.nconditions_14 + 1.nconditions_14#1.age35to44
	lincom 2.nconditions_14 + 2.nconditions_14#1.age35to44
	}
	
	/*
*******************************************************************************
* TABLE 7. FACILITY CHARCTERISTICS
*******************************************************************************


tab y2014_mpp_size if y2014_counter==1 & y2014_mpp_npi!="" & eligible_14==1

sum y2014_mpp_size if y2014_counter==1 & y2014_mpp_npi!="" & eligible_14==1

*Categorized/collapsed list
tab y2014_mppc if y2014_counter==1 & eligible_14==1, miss
tab y2014_mppc if y2014_counter==1 & eligible_14==1

*Full list (for appendix)
tab y2014_mpp_classification if y2014_counter==1 & y2014_mppc==1 & eligible_14==1
tab y2014_mpp_classification if y2014_counter==1 & y2014_mppc==5 & eligible_14==1
tab y2014_mpp_classification if y2014_counter==1 & y2014_mppc==9 & eligible_14==1
tab y2014_mpp_classification if y2014_counter==1 & y2014_mppc==10 & eligible_14==1
	





	
*******************************************************************************
* TABLE 4. WOMAN-LEVEL CONTRACEPTIVE MEASURES BY FACILITY CHARACTERISTICS
*******************************************************************************

foreach v in anyst_1mo_ep14_sum_id any_1mo_ep14_sum_id larc_1mo_ep14_sum_id	larc_12mo_ep14_sum_id {	
	*2014
	tab y2014_mppc `v' if eligible_14==1 , row chi2 nokey
	}

*******************************************************************************
* TABLE. MULTILEVEL MODELS
*******************************************************************************

*two level (provider, patient) models 2014
foreach y in anyst_1mo_ep14_sum_id any_1mo_ep14_sum_id larc_1mo_ep14_sum_id larc_12mo_ep14_sum_id {
	melogit `y' if eligible_14==1 & y2014_mpp_npi!=""  || y2014_mpp_npi: , or
	estat icc	
	melogit `y' i.y2014_mppc if eligible_14==1 & y2014_mpp_npi!=""  || y2014_mpp_npi: , or
	estat icc	
	melogit `y'  i.y2014_mppc b2.age5_14 i.covtypev2 if eligible_14==1 & y2014_mpp_npi!=""  || y2014_mpp_npi: , or
	estat icc
	}

*two level (provider, patient) models 2014
foreach y in anyst_1mo_ep14_sum_id any_1mo_ep14_sum_id larc_1mo_ep14_sum_id larc_12mo_ep14_sum_id {
	melogit `y'  i.y2014_mppc b2.age5_14 i.covtypev2 if eligible_14==1 & y2014_mpp_npi!=""  || y2014_mpp_npi: , or
	}
	
	
/* THESE ARE SLOW
*two level (patient, month) empty model 2013
melogit anyst_ep13_sum_id if eligible_13==1 || patient_id: , binomial(mo_arep_13_sum_id)
estat icc
*/


/* THESE AREN'T WORKING YET (NEED INITIAL VALUE ESTIMATES)
*three level (provider, patient, month) empty model 2013
timer clear
timer on 1
melogit anyst_ep13_sum_id if eligible_13==1 & y2013_mpp_npi!=""  || y2013_mpp_npi: || patient_id: , binomial(mo_arep_13_sum_id)
estat icc
timer off 1
timer list
*/
/*

*full model 2013
melogit larcvn13 i.age5_13 i.covtypev2 i.cv_disease_ever13 i.cv_risk_ever13 ///
		i.vte_ever13 i.pid_ever13 i.asthma_ever13 i.autoimmune_ever13 ///
		i.abortion_13 i.delivery_13 if eligible_13==1 || provider_id:
estat icc
		
*empty model 2014
melogit larcvn14 if eligible_14==1 || provider_id:
estat icc

*full model 2014
melogit larcvn14 i.age5_14 i.covtypev2 i.cv_disease_ever14 i.cv_risk_ever14 ///
		i.vte_ever14 i.pid_ever14 i.asthma_ever14 i.autoimmune_ever14 ///
		i.abortion_14 i.delivery_14 if eligible_14==1 || provider_id:
estat icc

*/

*******************************************************************************
* TABLE S1. PID DESCRIPTIVES
*******************************************************************************

* PID by age and insurance
tab  age5_14 pid_ever14 if eligible_14==1, row nokey
tab  covtypev2 pid_ever14 if eligible_14==1, row nokey



*******************************************************************************
* TABLE S2. PROVIDER GROUPING, DETAIL
*******************************************************************************

*Full list (for appendix)
tab y2014_mpp_classification if y2014_mppc==5 & eligible_14==1 & y2014_counter==1
tab y2014_mpp_classification if y2014_mppc==9 & eligible_14==1 & y2014_counter==1
tab y2014_mpp_classification if y2014_mppc==10 & eligible_14==1 & y2014_counter==1
	
/*
*******************************************************************************
* TABLE S3. MEDIAN NEIGHBORHOOD HH INCOME QUINTILES, DETAIL
*******************************************************************************
sum hhinc2014 if hhinc2014_5==1
sum hhinc2014 if hhinc2014_5==2
sum hhinc2014 if hhinc2014_5==3
sum hhinc2014 if hhinc2014_5==4
sum hhinc2014 if hhinc2014_5==5

*/


*******************************************************************************
* SANDBOX
*******************************************************************************




