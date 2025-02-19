


function forecast_data(UDE, test_data)
    UniversalDiffEq.check_test_data_names(UDE.data_frame, test_data)
    N, T, dims, test_data, test_times,  test_dataframe, test_series, inds, test_starts, test_lengths, labs = UniversalDiffEq.process_multi_data(test_data,UDE.time_column_name,UDE.series_column_name)
    N, T, dims, data, times,  dataframe, series, inds, starts, lengths, labs = UniversalDiffEq.process_multi_data(UDE.data_frame,UDE.time_column_name,UDE.series_column_name)

    series = 1
    time = times[starts[series]:(starts[series]+lengths[series]-1)]
    dat = data[:,starts[series]:(starts[series]+lengths[series]-1)]
    uhat = UDE.parameters.uhat[:,starts[series]:(starts[series]+lengths[series]-1)]
    series_ls = unique(test_dataframe[:,UDE.series_column_name])
    
    df = UniversalDiffEq.forecast(UDE, uhat[:,end], time[end], test_dataframe[test_dataframe[:,UDE.series_column_name] .== series_ls[1], UDE.time_column_name], series_ls[1])

    for series in 2:length(series_ls)

        time = times[starts[series]:(starts[series]+lengths[series]-1)]
        dat = data[:,starts[series]:(starts[series]+lengths[series]-1)]
        uhat = UDE.parameters.uhat[:,starts[series]:(starts[series]+lengths[series]-1)]

        test_time = test_times[test_starts[series]:(test_starts[series]+test_lengths[series]-1)]
        test_dat = test_data[:,test_starts[series]:(test_starts[series]+test_lengths[series]-1)]

        df = vcat(df,UniversalDiffEq.forecast(UDE, uhat[:,end], time[end], test_dataframe[test_dataframe[:,UDE.series_column_name] .== series_ls[series], UDE.time_column_name], series_ls[series]))
    end

    return df

end

function leave_future_out(model, training!, k, path)

    training_data = []
    testing_data = []
    data = model.data_frame
    series = unique(data.series)
    for i in 1:k
        data_series = data[data.series .== series[1],:]
        train = data_series[1:(end-i),:]
        test = data_series[(end-i+1):(end),:]
        for s in 2:length(series)
            data_series = data[data.series .== series[s],:]
            train_i = data_series[1:(end-i),:]
            test_i = data_series[(end-i+1):(end),:]
            train = vcat(train,train_i)
            test = vcat(test,test_i)
        end
        push!(training_data,train)
        push!(testing_data,test)
    end

    forecasts = Array{Any}(nothing, k)


    Threads.@threads for i in 1:k
        training_i = training_data[i]
        testing_i = testing_data[i]

        model_i = model.constructor(training_i,model.X)
        training!(model_i)
        
        forecasts_i = forecast_data(model_i, testing_i)

        file = string("/training_data_",i,".csv")
        CSV.write(string(path,file),training_i)
        file = string("/testing_data_",i,".csv")
        CSV.write(string(path,file),testing_i)
        file = string("/forecasts_",i,".csv")
        CSV.write(string(path,file),forecasts_i)

    end
    
    return training_data, testing_data, forecasts
end 

