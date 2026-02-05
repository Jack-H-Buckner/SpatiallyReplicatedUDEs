using DataFrames, CSV
print(pwd())

model_type=ARGS[1]
include("parameters.jl")
include("models/$model_type.jl")


# Read in data and select training data 
site = parse(Int,ARGS[2])
dat = CSV.read("data/processed_time_series.csv", DataFrame)[:,2:end]
dat = sort(dat,:PERIOD)

# get kelp variables as states and reserve period 55+ as final validation set
dat_states = dat[dat.SITE .== site,[:PERIOD,:MacJuv,:MacPyr]]


# select purple urchins and pycnopodia as covariates
X = dat[dat.SITE .== site,[:PERIOD,:StrPur,:PycHel]]
covar_names = ["StrPur","PycHel"]

using Base.Threads
include("/Users/johnbuckner/.julia/dev/UniversalDiffEq.jl/src/UniversalDiffEq.jl")
include("model_comparison_fn.jl")


comparison = (training,path_to_results) -> compare_models(training, X,init,covars_sets,tau_grid,
                                                        regularzation_grid, n_per_fold_inner, k_folds_inner;
                                                        save_results = true,path_to_results = path_to_results)


nested_cv(dat_states, X, comparison, n_per_fold_outer, k_folds_outer,
            "results/nested_cv", "$(model_type)_$(site)")