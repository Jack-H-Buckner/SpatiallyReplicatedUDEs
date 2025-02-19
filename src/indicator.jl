using DataFrames, CSV , UniversalDiffEq
include("cross_validation.jl")
# load kelp data 
dat = CSV.read("data/processed_time_series.csv", DataFrame)[:,2:end]
rename!(dat, ["time","series","juv","adult"])

# load rugosity and inverts data 
X = CSV.read("data/processed_rugosity.csv", DataFrame)[:,[2,3,5,7]]
rename!(X, ["time","series", "urchin",  "rugosity"])

# load observation error estimates (Calculated standard error of transects)
Vars = CSV.read("data/kelp_obs_errors.csv", DataFrame)[:,2:end]
Σ_kelp = [Vars.sigma2[1] 0 ; 0 Vars.sigma2[2]]
Σ_kelp


# build neural network with 9 inputs and 2 outputs 
NN, NNparameters = SimpleNeuralNetwork(2+7,2,hidden = 5)

# define derivatives (nerual network only)
function derivs!(du,u,i,X,p,t)
    index = round(Int,i) 
    one_hot = zeros(6) 
    one_hot[index] = 1 # set index for site equal to one 
    inputs = vcat(vcat(u,X[1:1]),one_hot)
    du .=  NN(inputs ,p.NN)
end

# set parameters from neural network 
init_parameters = (NN = NNparameters, )

model = MultiCustomDerivatives(dat,X,derivs!,init_parameters;
                                proc_weight=0.25,obs_weight=1.0,reg_weight=10^-6,
                                time_column_name = "time", series_column_name = "series")

function training!(model)
    # train using conditional likelihood
    train!(model,loss_function = "conditional likelihood", optim_options = (maxiter = 100,step_size=0.05))
    # finish with a smaller step size 
    train!(model,loss_function = "conditional likelihood", optim_options = (maxiter = 250,step_size=0.01))
end

k = 20
training_data, testing_data, forecasts = leave_future_out(model, training!, k)

for i in 1:k 
    path = "/Users/johnbuckner/github/UDEsWithSpatialReplicates/results/indicator"
    file = string("/training_data_",i,".csv")
    CSV.write(string(path,file),training_data[i])
    file = string("/testing_data_",i,".csv")
    CSV.write(string(path,file),testing_data[i])
    file = string("/forecasts_",i,".csv")
    CSV.write(string(path,file),forecasts[i])
end 