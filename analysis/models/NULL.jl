
function init(training,X)

    function dudt(u,X,p,t)
        return [0.0,0.0]
    end

    init_parameters = (r = 0.1,)

    model = UniversalDiffEq.CustomDerivatives(training,X,dudt,
                                                init_parameters;time_column_name = "PERIOD")

    function training!(model)
        UniversalDiffEq.train!(model, verbose = false,
                loss_function = "spline gradient matching", 
                regularization_weight = 0.0, 
                optim_options = (maxiter = 2, step_size = 0.025), 
                loss_options = (σ = 0.05, τ = 0.1, T = 4*size(training)[1]))
    end

    return model, training!

end