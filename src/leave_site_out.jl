
using LinearAlgebra

function likelihood(model,data; Pν = false, Pη = false,α = 10^-3,β = 2,κ = 0.0)
    
    # estiamte obs and proce errors if not provided
    if !Pν
        Pν,_ = UniversalDiffEq.get_residual_sample_cov(model)
    end

    if !Pη
        _,Pη = UniversalDiffEq.get_residual_sample_cov(model)
    end 

    # process data and initialize likeihood for one time series 
    single_loss = UniversalDiffEq.single_marginal_likelihood(model,0.0,Pη,α,β,κ)
    N, T, dims, data, times,  dataframe, series, inds, starts, lengths, varnames, labels_df = process_multi_data(data, UDE.time_column_name, UDE.series_column_name)

    # assign values for process errors and model parmaters in a CA
    Pνchol = Matrix(cholesky(Pν).L)
    H = Matrix(I,dims,dims)
    params = ComponentArray((UDE = model.parameters, Pν = Pνchol))

    # loop over sites and calcualte cummulative log-likeihood
    ll = 0
    for i in eachindex(starts)
        ll+= single_loss(params,i,starts,lengths)
    end

    return ll, Pν, Pη, H 

end 






function leave_site_out_indicator(model, training!, path, Ntrain)


    ### define a set of derivatives with all indicators equal to zero ###
    function derivs!(du,u,i,X,p,t)
        one_hot = zeros(Ntrain) 
        inputs = vcat(vcat(u,X[1:1]),one_hot)
        du .=  NN(inputs ,p.NN)
    end

    
    Threads.@threads for i in unique(model.data_frame.series)
        # construct training and test by leaving out series i
        train_i = model.data_frame[model.data_frame.series .!= i,:]
        test_i = model.data_frame[model.data_frame.series .== i,:]

        # build and fit model 
        model_i = model.constructor(train_i,model.X)
        training!(model_i)

        ### set up a new model without indicators equal to zero 
        test_model_i = MultiCustomDerivatives(test_i,model.X,derivs!,model_i.parameters.process_model;time_column_name = "time", series_column_name = "series")

        ll, Pν, Pη, H  = likelihood(test_model_i,test_i)
        push!(likelihoods,ll)

        ## add proces erros to paramters !!!
        Pνchol = Matrix(cholesky(Pν).L)
        params = ComponentArray((UDE = test_model_i.parameters, Pν = Pνchol))    
        estimates, Px = UniversalDiffEq.ukf_smooth(test_model_i,params,H,Pη,L,10^-3,2,0.0)
        
        # save results 
        file = string("/training_data_",i,".csv")
        CSV.write(string(path,file),train_i)
        file = string("/testing_data_",i,".csv")
        CSV.write(string(path,file),test_i)
        file = string("/estimates_",i,".csv")
        CSV.write(string(path,file),estimates)
        file = string("/likelihood_",i,".csv")
        CSV.write(string(path,file),DataFrame(ll = [ll]))

    end 

end 





function leave_site_out(model, training!, path)


    Threads.@threads for i in unique(model.data_frame.series)
        # construct training and test by leaving out series i
        train_i = model.data_frame[model.data_frame.series .!= i,:]
        test_i = model.data_frame[model.data_frame.series .== i,:]

        # build and fit model 
        model_i = model.constructor(train_i,model.X)
        training!(model_i)

        # calcualte marginal likeihood 
        ll, Pν, Pη, H  = likelihood(model_i,test_i)
        push!(likelihoods,ll)

        ## add proces erros to paramters ###
        Pνchol = Matrix(cholesky(Pν).L)
        params = ComponentArray((UDE = test_model_i.parameters, Pν = Pνchol))    
        estimates, Px = UniversalDiffEq.ukf_smooth(test_model_i,params,H,Pη,L,10^-3,2,0.0)

        # save results 
        file = string("/training_data_",i,".csv")
        CSV.write(string(path,file),train_i)
        file = string("/testing_data_",i,".csv")
        CSV.write(string(path,file),test_i)
        file = string("/estimates_",i,".csv")
        CSV.write(string(path,file),estimates)
        file = string("/likelihood_",i,".csv")
        CSV.write(string(path,file),DataFrame(ll = [ll]))

    end 

end 

