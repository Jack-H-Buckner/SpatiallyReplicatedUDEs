function leave_site_out_i(model, training!,i)

    training_inds = model.data_frame[:,model.series_column_name] .!= i 
    testing_inds = model.data_frame[:,model.series_column_name]  .== i

    training_i = model.data_frame[training_inds,:]
    testing_i = model.data_frame[testing_inds,:]

    model_i = model.constructor(training_i)
    training!(model_i)
    inds =  unique(model_i.data_frame[:,model.series_column_name])
    preds = []
    for j in inds
        testing_i[:,model.series_column_name] .= j
        push!(preds,UniversalDiffEq.predict(model_i,testing_i))
    end
    tmin = minimum(testing_i[:,model.time_column_name])
    testing_i = testing_i[testing_i[:,model.time_column_name] .> tmin,:]
    return testing_i, training_i, preds 
end 


function energy_score(testing,preds,model)

    M = length(preds)
    T = length(testing[:,1])

    # remove time and sereis column names 
    testing = testing[:,names(testing).!=model.time_column_name]
    testing = testing[:,names(testing).!=model.series_column_name]
    for i in 1:M
        preds[i] = preds[i][:,names(preds[i]).!=model.time_column_name]
        preds[i] = preds[i][:,names(preds[i]).!=model.series_column_name]
    end 
    score = 0
    for t in 1:T
        for i in 1:M
            pred_i = Vector(preds[i][t,1:end])
            test_i = Vector(testing[t,1:end])
            score += 1/M * sum(sqrt.((pred_i .- test_i).^2))
            for j in 1:M
                pred_j = Vector(preds[j][t,1:end])
                score += -1/(2*M^2) * sum(sqrt.((pred_i - pred_j).^2))
            end
        end
    end 

    return score/T
end 

using StatsBase
function leave_site_out(model, training!; sites = length(unique(model.data_frame[:,model.series_column_name])))
    
    site_ls = sample(unique(model.data_frame[:,model.series_column_name]),sites,replace=false)
    scores = zeros(length(site_ls))

    Threads.@threads for i in site_ls
        testing, training, preds  =  leave_site_out_i(model, training!,i)
        scores[i] = energy_score(testing,preds,model)
    end

    return sum(scores)/length(scores)
end

