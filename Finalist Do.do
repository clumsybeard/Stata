#read data
import excel "C:\Users\PC\Documents\Personal\Project\Gold.xls", sheet("Gold Futures Historical Data") firstrow
#clean data
tsset Date
format Date  %td
bcal create mycal , from(Date)
bcal create Date , from(Date)
gen date=td(1jan2019)+_n-1
tsset date
format date %td
tsset date
bcal create date1, from (date)
tsset date, daily
#create price diagram
twoway (tsline Price)
graph save Graph "C:\Users\PC\Documents\Personal\Project\tsline Price.gph"
#stationarity check
dfuller Price, noconstant lags(1)
gen log_Price=log(Price)
dfuller log_Price, noconstant lags(1)
gen dPrice=D.Price
dfuller dPrice, noconstant lags(1)
twoway (tsline Price) (tsline dPrice)
graph save Graph "C:\Users\PC\Documents\Personal\Project\log_Price non_stationary.gph"
#Fitting ARMA Model
capture program drop Cyrus
program Cyrus
global F %6.2f 
global G %5.0f

di "Model" _col(15) "LL" _col(25) "df" _col(35) "AIC" _col(45) $F "BIC" _col(55) "HQIC"
local aic = 99999999
local sbic = 99999999
forv ar = 0/2 {
    forv ma = 0/2 {
        qui arima dPrice, arima(`ar',0,`ma')
        local df = e(rank)
        local ll = e(ll)
        local N = e(N)
        local aic = 2*`df' - 2*`ll'
        local bic = ln(`N')*(`df') - 2*`ll'
        local hqic = 2*ln(ln(`N'))*(`df') - 2*`ll'
        di "ARMA(`ar',`ma')" $F _col(15) `ll' _col(25) $G `df' _col(35) $F `aic' _col(45) $F `bic' _col(55) $F `hqic'
    }
}
end

Cyrus
#forecasting model
tsappend, add(900)
forecast create Gold
regress Price L(1/2)Price
estimates store Gold
forecast estimates Gold
forecast solve, prefix(fc) begin(td(04sep2022)) end(td(19feb2025)) actuals simulate(beta, statistic(mean, prefix(mean)) statistic(stddev, prefix(sd)))
gen ub = meanPrice +1.645* sdPrice
gen lb1 = meanPrice -1.645* sdPrice
#create forecasted diagram including upper and lower bounds
tsline Price fcPrice ub lb1
graph save Graph "C:\Users\PC\Documents\Personal\Project\Final Prediction.gph"

