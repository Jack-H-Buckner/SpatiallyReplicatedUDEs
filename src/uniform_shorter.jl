using DataFrames, CSV , UniversalDiffEq
include("cross_validation.jl")
# load kelp data 
dat = CSV.read("data/processed_time_series.csv", DataFrame)[:,2:end]
rename!(dat, ["time","series","juv","adult"])
dat = dat[dat.time .< 30,:]

# load rugosity and inverts data 
X = CSV.read("data/processed_rugosity.csv", DataFrame)[:,[2,3,5,7]]
rename!(X, ["time","series", "urchin",  "rugosity"])

# load observation error estimates (Calculated standard error of transects)
Vars = CSV.read("data/kelp_obs_errors.csv", DataFrame)[:,2:end]
Σ_kelp = [Vars.sigma2[1] 0 ; 0 Vars.sigma2[2]]
Σ_kelp


# build neural network with 9 inputs and 2 outputs 
NN, NNparameters = SimpleNeuralNetwork(2+1,2,hidden = 5)

# define derivatives (nerual network only)
function derivs!(du,u,i,X,p,t)
    inputs = vcat(u,X[1:1])
    du .=  NN(inputs ,p.NN)
end

# set parameters from neural network 
init_parameters = (NN = NNparameters, )

model = MultiCustomDerivatives(dat,X,derivs!,init_parameters;
                                proc_weight=0.25,obs_weight=1.0,reg_weight=10^-6,
                                time_column_name = "time", series_column_name = "series")


function training!(model)
    # train using conditional likelihood
    train!(model,loss_function = "conditional likelihood", optim_options = (maxiter = 100,step_size=0.05),verbose = false)
    # finish with a smaller step size 
    train!(model,loss_function = "conditional likelihood", optim_options = (maxiter = 250,step_size=0.01),verbose = false)
end

k = 10
path = "/Users/johnbuckner/github/UDEsWithSpatialReplicates/results/uniform_shorter"
leave_future_out(model, training!, k, path)

