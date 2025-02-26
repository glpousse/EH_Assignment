/* Economic history assignment - 2
27 Nov 2024
Guillaume Pousse*/

**** PART 1 ****
****************

clear all
use "/Users/glpou/Downloads/JST_new.dta"

xtset ifs year

// tloans contains all loans to non-financial private sector - including businesses and households
gen nominal_credit = tloans 
gen real_credit = nominal_credit/cpi
// Generates 1437 missing observations (parts of total credit data) - consider allowing missing values for some?

gen lag1_real_credit = log(real_credit) - log(L1.real_credit)
gen lag2_real_credit = log(L1.real_credit) - log(L2.real_credit)
gen lag3_real_credit = log(L2.real_credit) - log(L3.real_credit)
gen lag4_real_credit = log(L3.real_credit) - log(L4.real_credit)
gen lag5_real_credit = log(L4.real_credit) - log(L5.real_credit)


****** Q1 - Running logit model with fixed effects, testing for joint significance of five lags credit growth ******
xtlogit crisisJST lag1_real_credit lag2_real_credit lag3_real_credit lag4_real_credit lag5_real_credit, fe
test lag1_real_credit lag2_real_credit lag3_real_credit lag4_real_credit lag5_real_credit

****** Q2 - Repeating with BVX crisis dates ******
clear all
use "/Users/glpou/Downloads/BVX replication kit/data/BVX_annual_regdata.dta"
keep year ISO3 RC
rename ISO3 iso
merge 1:1 iso year using "/Users/glpou/Downloads/JST_new.dta"

// We have to drop countries not included in the earlier analysis
drop if missing(country)

// repeat cleaning done earlier
xtset ifs year

// tloans contains all loans to non-financial private sector - including businesses and households
gen nominal_credit = tloans 
gen real_credit = nominal_credit/cpi
// Generates 1437 missing observations (parts of total credit data) - consider allowing missing values for some?

gen lag1_real_credit = log(real_credit) - log(L1.real_credit)
gen lag2_real_credit = log(L1.real_credit) - log(L2.real_credit)
gen lag3_real_credit = log(L2.real_credit) - log(L3.real_credit)
gen lag4_real_credit = log(L3.real_credit) - log(L4.real_credit)
gen lag5_real_credit = log(L4.real_credit) - log(L5.real_credit)

xtlogit RC lag1_real_credit lag2_real_credit lag3_real_credit lag4_real_credit lag5_real_credit, fe

// Wald test for joint significance
test lag1_real_credit lag2_real_credit lag3_real_credit lag4_real_credit lag5_real_credit

****** Q3 - Used 5-year change in the ratio of credit over GDP as a predictor ******

gen credit_gdp_ratio = real_credit/rgdpmad
gen credit_gdp_5yr = credit_gdp_ratio - L5.credit_gdp_ratio

xtlogit crisisJST credit_gdp_5yr, fe

****** ii. Model Evaluation ******

****** Q1

gen train = year <= 1984
gen test = year > 1984
logit crisisJST lag1_real_credit lag2_real_credit lag3_real_credit lag4_real_credit lag5_real_credit i.ifs if train == 1

// Getting predictions using in-sample data
predict prediction if train == 1
predict prediction_test if train == 0

roctab crisisJST prediction, graph
graph save "roc_in_sample.gph", replace  // Save in-sample ROC

roctab crisisJST prediction_test, graph
graph save "roc_out_sample.gph", replace  // Save out-of-sample ROC

graph combine "roc_in_sample.gph" "roc_out_sample.gph", title("ROC Curves: In-sample vs. Out-of-sample") col(1) 

****** Q2
gen log_money = log(money)

gen lag1_money = log_money - L1.log_money
gen lag2_money = L1.log_money - L2.log_money
gen lag3_money = L2.log_money - L3.log_money
gen lag4_money = L3.log_money - L4.log_money
gen lag5_money = L4.log_money - L5.log_money

// Train the model with in-sample data
logit crisisJST lag1_money lag2_money lag3_money lag4_money lag5_money i.ifs if train == 1
predict prediction_money if train == 1
predict prediction_money_test if train == 0

roctab crisisJST prediction_money, graph
graph save "roc_in_sample_money.gph", replace  // Save in-sample ROC

roctab crisisJST prediction_money_test, graph
graph save "roc_out_sample_money.gph", replace  // Save out-of-sample ROC
graph combine "roc_in_sample_money.gph" "roc_out_sample_money.gph", title("ROC Curves: In-sample vs. Out-of-sample (Money)") col(1)  // Stack vertically

****** Q4

// Obtain the public debt
gen pdebt = debtgdp * gdp
gen log_pdebt = log(pdebt)

gen lag1_pdebt= log_pdebt - L1.log_pdebt
gen lag2_pdebt = L1.log_pdebt - L2.log_pdebt
gen lag3_pdebt = L2.log_pdebt - L3.log_pdebt
gen lag4_pdebt = L3.log_pdebt - L4.log_pdebt
gen lag5_pdebt = L4.log_pdebt - L5.log_pdebt

// Train the model with in-sample data
logit crisisJST lag1_pdebt lag2_pdebt lag3_pdebt lag4_pdebt lag5_pdebt i.ifs if train == 1
predict prediction_debt if train == 1, 
predict prediction_debt_test if train == 0

roctab crisisJST prediction_debt if train == 1, graph
graph save "roc_in_sample_debt.gph", replace  // Save in-sample ROC

roctab crisisJST prediction_debt_test if train == 0, graph
graph save "roc_out_sample_debt.gph", replace  // Save out-of-sample ROC

graph combine "roc_in_sample_debt.gph" "roc_out_sample_debt.gph", title("ROC Curves: In-sample vs. Out-of-sample (Public Debt)") col(1)  // Stack vertically

**** PART 2 ****
****************

clear all
use "/Users/glpou/Downloads/JST_new.dta"
merge 1:1 iso year using "/Users/glpou/Downloads/RecessionDummies.dta"

* Replace missing recession dummy values with 0
replace N = 0 if N == .
replace F = 0 if F == .

* Generate log of GDP per capita (real GDP)
gen log_rgdpbarro = log(rgdpbarro)

* Ensure the data is sorted by panel identifier (ifs) and time (year)
sort ifs year

* Loop over horizons (1 to 5 years)
forval h = 1/5 {
    * Generate the difference in log_rgdpbarro for each horizon dynamically
    gen delta_log_rgdpbarro_h`h' = F`h'.log_rgdpbarro - log_rgdpbarro[_n-1] if !missing(log_rgdpbarro[_n-1])

    * Regress the difference on normal and financial recession dummies, including fixed effects
    regress delta_log_rgdpbarro_h`h' N F i.ifs, robust

    * Save the coefficients for each horizon
    scalar coef_normal_`h' = _b[N]
    scalar coef_financial_`h' = _b[F]

    * Save the 95% confidence intervals for normal and financial recession dummies
    scalar lower_normal_`h' = _b[N] - (1.96 * _se[N])
    scalar upper_normal_`h' = _b[N] + (1.96 * _se[N])
    
    scalar lower_financial_`h' = _b[F] - (1.96 * _se[F])
    scalar upper_financial_`h' = _b[F] + (1.96 * _se[F])
	
	di "Normal Coefficient at Horizon `h': " coef_normal_`h'
	di "Financial Coefficient at Horizon `h': " coef_financial_`h'
	di "Lower Normal CI at Horizon `h': " lower_normal_`h'
	di "Upper Normal CI at Horizon `h': " upper_normal_`h'
	di "Lower Financial CI at Horizon `h': " lower_financial_`h'
	di "Upper Financial CI at Horizon `h': " upper_financial_`h'
}

* Step 1: Create a new dataset to store the IRF coefficients and confidence intervals
clear 

* Step 1: Create an empty dataset with 5 observations
set obs 5

* Step 2: Create the 'horizon' variable and fill it with values 1 to 5
gen horizon = _n
gen coef_normal = .
gen coef_financial = .
gen lower_normal = .
gen upper_normal = .
gen lower_financial = .
gen upper_financial = .

* Fill the 'horizon' variable with values 1 to 5
replace horizon = 1 in 1
replace horizon = 2 in 2
replace horizon = 3 in 3
replace horizon = 4 in 4
replace horizon = 5 in 5

* Step 2: Insert the scalar values into the dataset
replace coef_normal = coef_normal_1 if horizon == 1
replace coef_normal = coef_normal_2 if horizon == 2
replace coef_normal = coef_normal_3 if horizon == 3
replace coef_normal = coef_normal_4 if horizon == 4
replace coef_normal = coef_normal_5 if horizon == 5

replace coef_financial = coef_financial_1 if horizon == 1
replace coef_financial = coef_financial_2 if horizon == 2
replace coef_financial = coef_financial_3 if horizon == 3
replace coef_financial = coef_financial_4 if horizon == 4
replace coef_financial = coef_financial_5 if horizon == 5

replace lower_normal = lower_normal_1 if horizon == 1
replace lower_normal = lower_normal_2 if horizon == 2
replace lower_normal = lower_normal_3 if horizon == 3
replace lower_normal = lower_normal_4 if horizon == 4
replace lower_normal = lower_normal_5 if horizon == 5

replace upper_normal = upper_normal_1 if horizon == 1
replace upper_normal = upper_normal_2 if horizon == 2
replace upper_normal = upper_normal_3 if horizon == 3
replace upper_normal = upper_normal_4 if horizon == 4
replace upper_normal = upper_normal_5 if horizon == 5

replace lower_financial = lower_financial_1 if horizon == 1
replace lower_financial = lower_financial_2 if horizon == 2
replace lower_financial = lower_financial_3 if horizon == 3
replace lower_financial = lower_financial_4 if horizon == 4
replace lower_financial = lower_financial_5 if horizon == 5

replace upper_financial = upper_financial_1 if horizon == 1
replace upper_financial = upper_financial_2 if horizon == 2
replace upper_financial = upper_financial_3 if horizon == 3
replace upper_financial = upper_financial_4 if horizon == 4
replace upper_financial = upper_financial_5 if horizon == 5

* Step 3: Plot the Impulse Response Function (IRF) with Confidence Intervals
* Create the graph for Normal Recession Coefficients and Confidence Intervals
twoway (line coef_normal horizon, lcolor(blue) lwidth(medium) lpattern(solid) ///
        legend(label(1 "Normal Recession Coefficient"))) ///
       (rarea lower_normal upper_normal horizon, color(blue%30) lcolor(blue%30) ///
        lpattern(solid) legend(label(2 "Normal Recession 95% CI"))) ///
       , title("Impulse Response Function: Normal Recession") ///
         xlabel(1(1)5) ylabel(, grid) legend(position(11))

* Create the graph for Financial Recession Coefficients and Confidence Intervals
twoway (line coef_financial horizon, lcolor(red) lwidth(medium) lpattern(solid) ///
        legend(label(1 "Financial Recession Coefficient"))) ///
       (rarea lower_financial upper_financial horizon, color(red%30) lcolor(red%30) ///
        lpattern(solid) legend(label(2 "Financial Recession 95% CI"))) ///
       , title("Impulse Response Function: Financial Recession") ///
         xlabel(1(1)5) ylabel(, grid) legend(position(11))
	
* Comparison
twoway (line coef_normal horizon, lcolor(blue) lwidth(medium) lpattern(solid) ///
        legend(label(1 "Normal Recession Coefficient"))) ///
       (line coef_financial horizon, lcolor(red) lwidth(medium) lpattern(solid) ///
        legend(label(2 "Financial Recession Coefficient"))) ///
       , title("Impulse Response Functions: Normal vs. Financial Recession") ///
         xlabel(1(1)5) ylabel(, grid) legend(position(11))
		 
****** END ******
