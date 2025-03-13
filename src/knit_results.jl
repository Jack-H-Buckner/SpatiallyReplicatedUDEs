

using CSV, DataFrames

function main()
    forecast_ = CSV.read(string("results/",ARGS[1],"/forecasts_1.csv"), DataFrame)
    testing = CSV.read(string("results/",ARGS[1],"/testing_data_1.csv"), DataFrame)
    forecast_.time .= 2  .+ forecast_.time .- 77
    testing.time .= 2 .+testing.time .- 77
    rename!(forecast_,["series","time", "juv_f", "adult_f"])
    dat = innerjoin(forecast_, testing, on = [:time,:series])
    dat.sim .= 1
    for i in 2:15
        forecast_ = CSV.read(string("results/",ARGS[1],"/forecasts_",i,".csv"), DataFrame)
        testing = CSV.read(string("results/",ARGS[1],"/testing_data_",i,".csv"), DataFrame)
        forecast_.time .= (1+i) .+ forecast_.time .- 77
        testing.time .= (1+i) .+testing.time .- 77
        rename!(forecast_,["series","time", "juv_f", "adult_f"])
        dat_i = innerjoin(forecast_, testing, on = [:time,:series])
        dat_i.sim .= i
        dat = vcat(dat,dat_i)
    end

    CSV.write(string("results/",ARGS[1],"/all.csv"),dat)
end

main()