

using CSV, DataFrames


forcast = CSV("../results/covariates/forecast_",i,".csv", DataFrame)
testing = CSV("../results/covariates/testing_data_",i,".csv", DataFrame)
forecast.time .= 77 .- forecast.time
testing.time .= 77 .- testing.time

forecast.time .= 77 .- forecast.time
testing.time .= 77 .- testing.time
dat = innerjoin(forecast, testing, on = [:time,:series])
for i in 2:20

    forcast = CSV("../results/covariates/forecast_",i,".csv", DataFrame)
    testing = CSV("../results/covariates/testing_data_",i,".csv", DataFrame)
    forecast.time .= 77 .- forecast.time
    testing.time .= 77 .- testing.time
    
end