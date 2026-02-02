function compare_models(training, X,init,covars_sets,tau_grid,
                        regularzation_grid, n_per_fold, k_folds;
                        save_results = true,path_to_results = "results",
                        file_tag = "")

    # loop over grid and calcualte metrics
    na, nb, nc = length(covars_sets), length(tau_grid), length(regularzation_grid)
    n = na * nb * nc

    # example: store results (Any is flexible; specialize if you know the type)
    results = Vector{Any}(undef, n)

    @threads for idx in 1:n
        # map linear idx -> (ia, ib, ic) in column-major order
        t = idx - 1
        ia = (t % na) + 1
        t ÷= na
        ib = (t % nb) + 1
        ic = (t ÷ nb) + 1

        covars = covars_sets[ia]
        tau_ = tau_grid[ib]
        regularization = regularzation_grid[ic]

        model,training! = init(training,X,covars, tau_, regularization)
        summary_df,raw_df=UniversalDiffEq.leave_future_out_predict(model, training!, n_per_fold , k_folds)
        summary_df.covars .= repeat([string(covar_names[covars])],size(summary_df)[1])
        print(ia," ")
        println(repeat([ia],size(summary_df)[1]))
        summary_df.covars_ind .= repeat([ia],size(summary_df)[1])
        summary_df.tau_ .= repeat([tau_],size(summary_df)[1])
        summary_df.tau_ind .= repeat([ib],size(summary_df)[1])
        summary_df.regularization .= repeat([regularization],size(summary_df)[1])
        summary_df.regularization_ind .= repeat([ic],size(summary_df)[1])
        results[idx] = summary_df

    end


    # combine and save model skill summaries
    combined_df = reduce(vcat, results)

    # average model skill over state variables and select best model
    gdf = groupby(combined_df, [:covars,:covars_ind,:tau_,:tau_ind,:regularization,:regularization_ind])
    summary_df = combine(gdf, :MSE => sum => :MSE)
    best_model = summary_df[summary_df.MSE .== minimum(summary_df.MSE),:]
    

    # select best model for juviniles
    juv_df = combined_df[combined_df.variable .== "MacJuv",:]
    best_model_juv = juv_df[juv_df.MSE .== minimum(juv_df.MSE),:]
    

    # select best model for adults
    adult_df = combined_df[combined_df.variable .== "MacPyr",:]
    best_model_adults = adult_df[adult_df.MSE .== minimum(adult_df.MSE),:]
    
    if save_results
        if !isdir("$path_to_results")
            mkpath("$path_to_results")
        end
        CSV.write("$path_to_results/model_comparison_$file_tag.csv",combined_df)
        CSV.write("$path_to_results/best_model_$file_tag.csv",best_model)
        CSV.write("$path_to_results/best_model_juv_$file_tag.csv",best_model_juv)
        CSV.write("$path_to_results/best_model_adults_$file_tag.csv",best_model_adults)
    end 

    # init_best_model
    covars_best = covars_sets[best_model.covars_ind[1]]
    tau_best = tau_grid[best_model.tau_ind[1]]
    reg_best = regularzation_grid[best_model.regularization_ind[1]]
    model,training! = init(training,X,covars_best, tau_best, reg_best)
    training!(model)

    # init_best_model
    covars_best = covars_sets[best_model_juv.covars_ind[1]]
    tau_best = tau_grid[best_model_juv.tau_ind[1]]
    reg_best = regularzation_grid[best_model_juv.regularization_ind[1]]
    model_juv,training_juv! = init(training,X,covars_best, tau_best, reg_best)
    training_juv!(model_juv)

    # init_best_model
    covars_best = covars_sets[best_model_adults.covars_ind[1]]
    tau_best = tau_grid[best_model_adults.tau_ind[1]]
    reg_best = regularzation_grid[best_model_adults.regularization_ind[1]]
    model_adult,training_adult! = init(training,X,covars_best, tau_best, reg_best)
    training_adult!(model_adult)

    return model,model_juv,model_adult
end




function nested_cv(data,X,comparison, n_per_fold::Int, k_folds::Int,path_to_results,file_tag)
    
    training_data = []
    testing_data = []

    for i in n_per_fold:n_per_fold:(n_per_fold*k_folds)
        push!(training_data, data[1:(end-i),:])
        push!(testing_data, data[(end-i):(end-i+n_per_fold),:]) # including the last data point for one step ahead predictions
    end

    preds = Array{Any}(nothing, k_folds); preds_juv = Array{Any}(nothing, k_folds); preds_adults = Array{Any}(nothing, k_folds)
    obs = Array{Any}(nothing, k_folds); obs_juv = Array{Any}(nothing, k_folds); obs_adults = Array{Any}(nothing, k_folds)
    times = Array{Any}(nothing, k_folds); times_juv = Array{Any}(nothing, k_folds); times_adults = Array{Any}(nothing, k_folds)


    for i in 1:k_folds #Threads.@threads 


        training_i = training_data[i]
        testing_i = testing_data[i]
        
        model_i,model_juv_i,model_adults_i = comparison(training_i, "$path_to_results/fold_$i")
        inits,obs_i,preds_i = UniversalDiffEq.predictions(model_i, testing_i)
        inits,obs_i,preds_juv_i = UniversalDiffEq.predictions(model_juv_i, testing_i)
        inits,obs_i,preds_adults_i = UniversalDiffEq.predictions(model_adults_i, testing_i)

        delta_obs = obs_i .- inits
        delta_pred = preds_i .- inits
        delta_pred_juv = preds_juv_i .- inits
        delta_pred_adults = preds_adults_i .- inits
        
        preds[i] =  delta_pred 
        preds_juv[i] =  delta_pred_juv
        preds_adults[i] =  delta_pred_adults 

        obs[i] =  delta_obs
        times[i] = testing_i[2:end,model_i.time_column_name]

    end

    model,model_juv,model_adults = comparison(data,"$path_to_results/final_model_selection")

    summary_df,df = UniversalDiffEq.summarize_cv_results(model,preds,obs,times) 
    summary_df_juv,df_juv = UniversalDiffEq.summarize_cv_results(model_juv,preds_juv,obs,times) 
    summary_df_adult,df_adult = UniversalDiffEq.summarize_cv_results(model_adults,preds_adults,obs,times) 
    

    if !isdir("$path_to_results/nested_cv_results")
        mkpath("$path_to_results/nested_cv_results")
    end

    CSV.write("$path_to_results/nested_cv_results/all_$file_tag.csv",summary_df)
    CSV.write("$path_to_results/nested_cv_results/juv_$file_tag.csv",summary_df_juv)
    CSV.write("$path_to_results/nested_cv_results/adults_$file_tag.csv",summary_df_adult)


    return summary_df, summary_df_juv, summary_df_adult
end 