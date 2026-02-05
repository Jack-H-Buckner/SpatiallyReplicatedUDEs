function soft_plus(x)
    log(exp(x)+1)
end 

function get_scaling_factors(site)
    scaling_factors  = CSV.read("../data/scaling_factors.csv", DataFrame)[:,2:end]
    scaling_factors = scaling_factors[scaling_factors.SITE.==site,:]
    Xinds = [4,6]
    mean = scaling_factors.mean[Xinds]
    scale = scaling_factors.sd[Xinds]
    return scale, mean
end

function init(training,X,covars, tau_, regularization_weight, site)


    scale, mean =get_scaling_factors(site)

    NN_ma, NNparameters_ma = UniversalDiffEq.SimpleNeuralNetwork(1,2, hidden = 10, seed = 5491)
    NN_mo, NNparameters_mo = UniversalDiffEq.SimpleNeuralNetwork(2+length(covars),2, hidden = 10, seed = 5491)

    function dudt(u,X,p,t,covars,scale, mean)
        x_J, x_A = u
        inputs_mo = vcat(u[1:2], X[covars])
        inputs_ma = u[2:2]

        fmo_A, fmo_J = NN_mo(inputs_mo, p.NN_mo)
        fma = NN_ma(inputs_ma, p.NN_ma)[1]

        J = exp(scale[1]*x_J+mean[1])
        A = exp(scale[2]*x_A+mean[2])

        dJ = exp(p.r)*A/J - soft_plus.(fma) - soft_plus.(fmo_J)
        dA = soft_plus.(fma)*J/A - soft_plus.(fmo_A)
        du = [dJ,dA]

        return du
    end
    
    init_parameters = (NN_ma = NNparameters_ma,  NN_mo = NNparameters_mo, r = 0.5)

    model = UniversalDiffEq.CustomDerivatives(training,X,(u,X,p,t) -> dudt(u,X,p,t,covars,scale, mean),
                                                init_parameters;time_column_name = "PERIOD")

    function training!(model)
        UniversalDiffEq.train!(model, verbose = false,
                loss_function = "spline gradient matching", 
                regularization_weight = regularization_weight, 
                optim_options = (maxiter = 500, step_size = 0.025), 
                loss_options = (σ = 0.05, τ = tau_, T = 4*size(training)[1]))
    end

    return model, training!
end