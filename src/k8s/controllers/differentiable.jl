
include("controller.jl")
include("agent.jl")

mutable struct DifferentiableAgent <: Agent
end

mutable struct DifferentiableController <: Controller
    agents::Dict{String, DifferentiableAgent}
end


function add(controller::DifferentiableController, task::Dict{String, Any})
    @info "differentiable task added" task

    # check that solution doesn't already exist
    # create
end

function update(controller::DifferentiableController, task::Dict{String, Any})
    @info "differentiable task updated" task
end

function delete(controller::DifferentiableController, task::Dict{String, Any})
    @info "differentiable task deleted" task
end
