alias julia="/Applications/Julia-1.10.app/Contents/Resources/julia/bin/julia"
#julia -t 8 analysis/model_selection_tests.jl NODE 4
#julia -t 8 analysis/model_selection.jl NODE 4
julia -t 8 analysis/model_selection.jl UDE 4
