
"""
    Agent{}

Agent is an abstract type that represents a solution running on the cluster.
"""
abstract type Agent{} end

"""
    Runtime(agent::Agent, openapispec::Dict{String, Any})

Runtime holds the common runtime configuration for agents.
"""
mutable struct Runtime
    agent::Agent
    openapispec::Dict{String, Any}
    function Runtime(agent::Agent, openapispec::Dict{String, Any})
        new(agent, openapispec)
    end
end

function run(runtime::Runtime)
    # should setup a basic server based on the openapi definition

    # the different types of agents should be responsible for their own update functions.
end