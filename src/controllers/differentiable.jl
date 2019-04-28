
include("controller.jl")
include("agent.jl")

mutable struct DifferentiableAgent <: Agent
    function DifferentiableAgent()
    end
end

mutable struct DifferentiableController <: Controller
    agents::Dict{String, DifferentiableAgent}
    function DifferentiableController()
        agents = Dict{String, DifferentiableAgent}()
        new(agents)
    end
end


function add_task(controller::DifferentiableController, task::Dict{String, Any})
    # check that solution doesn't already exist
    @info "diff task added" task
    # create
end

function update_task(controller::DifferentiableController, task::Dict{String, Any})
    @info "diff task updated" task
end

function delete_task(controller::DifferentiableController, task::Dict{String, Any})
    @info "diff task deleted" task
end
