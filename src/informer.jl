import Kuber, HTTP, DataStructures, JSON, Dates

include("client.jl")
# include("controllers/Controllers.jl")

"""
    TaskListWatcher(client::K8sClient)

A TaskListWatcher will keep a cache of the current state of the Task CRDs in the cluster by watching
the resource and periodically listing it.
"""
mutable struct TaskListWatcher
    client::K8sClient
    chan::Channel
    tasks::Dict{String,Any}
    function TaskListWatcher(client::K8sClient, chan::Channel)
        new(client, chan, Dict{String,Any}())
    end
end

function listwatch(listwatcher::TaskListWatcher)
    @info "getting tasks"
    tasks = list_tasks(listwatcher)
    # @show tasks

    # check if task in in current cache otherwise send to chan
    for taskid in keys(tasks)
        task = tasks[taskid]
        existing = get(listwatcher.tasks, task["metadata"]["uid"], Dict{String, Any}())
        if length(existing) == 0
            @info "sending add/update to queue!"
            put!(listwatcher.chan, task)
            listwatcher.tasks[taskid] = task
        end
    end
    # check if any current tasks no longer exist, if so send to chan
    for taskid in keys(listwatcher.tasks)
        task = listwatcher.tasks[taskid]
        existing = get(tasks, task["metadata"]["uid"], Dict{String, Any}())
        if length(existing) == 0
            @info "sending deletion to queue!!"
            put!(listwatcher.chan, task)
            delete!(listwatcher.tasks, taskid)
        end
    end
end

function loop(listwatcher::TaskListWatcher, interval::Dates.Second)
    @info "starting loop..."
    while true
        listwatch(listwatcher)
        sleep(Dates.value(interval))
    end
end

function list_tasks(listwatcher::TaskListWatcher)::Dict{String, Any}
    resp = request(listwatcher.client, "GET", "/apis/kubemeta.ai/v1alpha1/tasks")
    str = String(resp.body)
    jobj = JSON.Parser.parse(str)
    currentTasks = Dict{String, Any}()
    for item in jobj["items"]
        uid = item["metadata"]["uid"]
        currentTasks[uid] = item
    end
    return currentTasks
end

function get_task(listwatcher::TaskListWatcher, name::String, namespace::String)::Dict{String, Any}
    uri = string("/apis/kubemeta.ai/v1alpha1/namespaces/", namespace, "/tasks/", name)
    resp = HTTP.Messages.Response()
    resp = request(listwatcher.client, "GET", uri)
    # @show resp
    if resp.status >= 300
        return Dict{String, Any}()
    end
    str = String(resp.body)
    jobj = JSON.Parser.parse(str)
    return jobj
end

function watch_task(listwatcher::TaskListWatcher)
    # TODO
end

# TODO: make this a more generic crd informer
"""
    TaskInformer(listwatcher::TaskListWatcher)

A TaskInformer will inform on what changes have occurred with the Task CRDs, and apply the appropriate
handler functions.
"""
mutable struct TaskInformer
    listwatcher::TaskListWatcher
    chan::Channel
    controller
    function TaskInformer(listwatcher::TaskListWatcher, chan::Channel, controller)
        new(listwatcher, chan, controller)
    end
end

function run(taskinformer::TaskInformer)
    @info "running async"
    @async loop(taskinformer.listwatcher, Dates.Second(2))
    while true
        @info "taking from chan"
        data = take!(taskinformer.chan)
        @debug "received data: " data
        dispatch(taskinformer.listwatcher, taskinformer.controller, data)
    end
end

function dispatch(listwatcher::TaskListWatcher, controller, task::Dict{String, Any})
    found = get_task(listwatcher, task["metadata"]["name"], task["metadata"]["namespace"])
    # task is missing
    if length(found) == 0
        @info "deleting task: " task
        delete_task(controller, task)
        return
    end
    # task is present, check if ids match
    if task["metadata"]["resourceVersion"] != found["metadata"]["resourceVersion"]
        @info "updating task: " task
        update_task(controller, task)
        return
    end
    # resource versions and names match, its an add
    @info "adding task: " task
    add_task(controller, task)
    return
end
