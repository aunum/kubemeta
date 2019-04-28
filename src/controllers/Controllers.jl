module Controllers

include("agent.jl")
include("controller.jl")
include("differentiable.jl")

export Controller, DifferentiableController, DifferentiableAgent, add_task, update_task, delete_task

end # module
