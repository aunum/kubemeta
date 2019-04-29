import HTTP, JSON2

"""
    Agent{}

Agent is an abstract type that represents a solution running on the cluster.
"""
abstract type Agent{} end

function deploy(agent::Agent)
end

"""
    Runtime(agent::Agent, openapispec::Dict{String, Any})

Runtime holds the common runtime configuration for agents.
"""
mutable struct Runtime
    agent::Agent
    openapispec::Dict{String, Any}
end

function run(runtime::Runtime)
    # should setup a basic server based on the openapi definition

    # the different types of agents should be responsible for their own update functions.
end

# use a plain `Dict` as a "data store"
const ANIMALS = Dict{Int, Animal}()

function processhandler(req::HTTP.Request)
    input = Dict{String, Any}()
    input = JSON2.read(IOBuffer(HTTP.payload(req)), input)
    # TODO: validate input off openapi spec

    # process

    output = Dict{String, Any}()

    # TODO: validate output off openapi spec
    return HTTP.Response(200, JSON2.write(output))
end

function errorhandler(req::HTTP.Request)
    error = Dict{String, Any}()
    error = JSON2.read(IOBuffer(HTTP.payload(req)), error)

    # process error

    return HTTP.Response(200)
end

mutable struct Stats
    kv::Dict{string, Any}
end

function statshandler(req::HTTP.Request)
    # get stats

    return HTTP.Response(200, JSON2.write(stats))
end


# define REST endpoints to dispatch to "service" functions
const AGENT_ROUTER = HTTP.Router()
HTTP.@register(AGENT_ROUTER, "POST", "/process", processhandler)
HTTP.@register(AGENT_ROUTER, "POST", "/error", errorhandler)
HTTP.@register(AGENT_ROUTER, "GET", "/stats", statshandler)

HTTP.serve(AGENT_ROUTER, Sockets.localhost, 8080)
