import HTTP, JSON2, Sockets

include("controllers/agent.jl")
include("informer.jl")

"""
    Router{}

Router proxies requests to downstream agent solutions.
"""
mutable struct Router
    agentinformer::Informer
end

function deploy(router::Router)
end

function run(router::Router)
    const AGENT_ROUTER = HTTP.Router()
    HTTP.@register(AGENT_ROUTER, "POST", "/process", processhandler)
    HTTP.@register(AGENT_ROUTER, "POST", "/error", errorhandler)
    HTTP.@register(AGENT_ROUTER, "GET", "/stats", statshandler)

    HTTP.serve(AGENT_ROUTER, Sockets.localhost, 8080)
end

function processproxyhandler(req::HTTP.Request)::HTTP.Response
    input = Dict{String, Any}()
    input = JSON2.read(IOBuffer(HTTP.payload(req)), input)
    # TODO: validate input off openapi spec

    # send to one or all downstream solutions
    # Reinforcement learning

    output = Dict{String, Any}()

    # TODO: validate output off openapi spec
    return HTTP.Response(200, JSON2.write(output))
end

function errorproxyhandler(req::HTTP.Request)::HTTP.Response
    error = Dict{String, Any}()
    error = JSON2.read(IOBuffer(HTTP.payload(req)), error)

    # process error

    return HTTP.Response(200)
end

mutable struct Stats
    agents::Dict{string, Agent}
    kv::Dict{string, Any}
end

function statsproxyhandler(req::HTTP.Request)::HTTP.Response
    # get stats

    stats = Stats(Dict{string, Agent}(), Dict{String, Any}())
    return HTTP.Response(200, JSON2.write(stats))
end

