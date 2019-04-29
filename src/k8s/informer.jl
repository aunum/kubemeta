import Kuber, HTTP, DataStructures, JSON, Dates

include("client.jl")
include("resource.jl")
include("controllers/Controllers.jl")

"""
    objectListWatcher(client::K8sClient)

A objectListWatcher will keep a cache of the current state of the object CRDs in the cluster by watching
the resource and periodically listing it.
"""
mutable struct ListWatcher
    client::K8sClient
    chan::Channel
    resource::Resource
    objects::Dict{String,Any}
end

function listwatch(listwatcher::ListWatcher)
    @info "listing objects"
    objects = list_objects(listwatcher)

    # check if object in in current cache otherwise send to chan
    for objectid in keys(objects)
        object = objects[objectid]
        existing = get(listwatcher.objects, object["metadata"]["uid"], Dict{String, Any}())
        if length(existing) == 0
            @info "sending add/update to queue"
            put!(listwatcher.chan, object)
            listwatcher.objects[objectid] = object
        end
    end
    # check if any current objects no longer exist, if so send to chan
    for objectid in keys(listwatcher.objects)
        object = listwatcher.objects[objectid]
        existing = get(objects, object["metadata"]["uid"], Dict{String, Any}())
        if length(existing) == 0
            @info "sending deletion to queue"
            put!(listwatcher.chan, object)
            delete!(listwatcher.objects, objectid)
        end
    end
end

function loop(listwatcher::ListWatcher, interval::Dates.Second)
    @info "starting loop..."
    while true
        listwatch(listwatcher)
        sleep(Dates.value(interval))
    end
end

function list_objects(listwatcher::ListWatcher)::Dict{String, Any}
    resp = list(listwatcher.client, listwatcher.resource)
    str = String(resp.body)
    jobj = JSON.Parser.parse(str)
    currentObjects = Dict{String, Any}()
    for item in jobj["items"]
        uid = item["metadata"]["uid"]
        currentObjects[uid] = item
    end
    return currentObjects
end

function watch_object(listwatcher::ListWatcher)
    # TODO
end

# TODO: make this a more generic crd informer
"""
    Informer(listwatcher::ListWatcher)

An Informer will inform on what changes have occurred with the Resources, and apply the appropriate
handler functions.
"""
mutable struct Informer
    listwatcher::ListWatcher
    chan::Channel
    resource::Resource
    controller
end

function run(informer::Informer)
    @info "running async"
    @async loop(informer.listwatcher, Dates.Second(2))
    while true
        @info "taking from chan"
        data = take!(informer.chan)
        @debug "received data: " data
        dispatch(informer.listwatcher, informer.resource, informer.controller, data)
    end
end

function dispatch(listwatcher::ListWatcher, resource::Resource, controller, object)
    found = get(listwatcher.client, resource, object["metadata"]["name"], object["metadata"]["namespace"])
    # object is missing
    if length(found) == 0
        @info "deleting object: " object
        delete(controller, object)
        return
    end
    # object is present, check if ids match
    if object["metadata"]["resourceVersion"] != found["metadata"]["resourceVersion"]
        @info "updating object: " object
        update(controller, object)
        return
    end
    # resource versions and names match, its an add
    @info "adding object: " object
    add(controller, object)
    return
end
