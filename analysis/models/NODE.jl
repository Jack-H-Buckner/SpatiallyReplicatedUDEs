
function init(training,X,covars, tau_, regularization_weight)

    NN, NNparameters = UniversalDiffEq.SimpleNeuralNetwork(2+length(covars),2, hidden = 10, seed = 5491)

    function dudt(u,X,p,t,covars)
        return NN(vcat(u,X[covars]), p.NN) # index 3 is pycnopodia  ,X[1:2]
    end

    init_parameters = (NN = NNparameters, )

    model = UniversalDiffEq.CustomDerivatives(training,X,(u,X,p,t) -> dudt(u,X,p,t,covars),
                                                init_parameters;time_column_name = "PERIOD")

    function training!(model)
        UniversalDiffEq.train!(model,  verbose = false,
                loss_function = "spline gradient matching", 
                regularization_weight = regularization_weight, 
                optim_options = (maxiter = 500, step_size = 0.025), 
                loss_options = (σ = 0.05, τ = tau_, T = 4*size(training)[1]))
    end

    return model, training!
    
end