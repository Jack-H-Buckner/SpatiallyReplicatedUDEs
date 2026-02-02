
function init(training,X)

    function dudt(u,X,p,t)
        return [0,0] 
    end

    init_parameters = NamedTyple()

    model = UniversalDiffEq.CustomDerivatives(training,X,(u,X,p,t) -> dudt(u,X,p,t),
                                                init_parameters;time_column_name = "PERIOD")

    function training!(model)
        UniversalDiffEq.train!(model, 
                loss_function = "spline gradient matching", 
                regularization_weight = 0.0, 
                optim_options = (maxiter = 2, step_size = 0.025), 
                loss_options = (σ = 0.05, τ = 0.0, T = 4*size(training)[1]))
    end

    return model, training!

end