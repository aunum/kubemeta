module Controllers

include("agent.jl")
include("differentiable.jl")

export Controller, DifferentiableController, DifferentiableAgent, add, update, delete

end # module
