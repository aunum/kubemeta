
include("controller.jl")
include("agent.jl")

mutable struct DifferentiableAgent <: Agent
    function DifferentiableAgent()
    end
end

mutable struct DifferentiableController <: Controller
    agents::Dict{String, DifferentiableAgent}
    function DifferentiableController()

    end
end


function add_task(controller::DifferentiableController, task::Dict{String, Any})
    # check that solution doesn't already exist

    # create
end

function update_task(controller::DifferentiableController, task::Dict{String, Any})

end

function delete_task(controller::DifferentiableController, task::Dict{String, Any})

end