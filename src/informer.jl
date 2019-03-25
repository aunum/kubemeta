import Kuber, HTTP, DataStructures, JSON, Dates

include("client.jl")

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
    println("getting tasks")
    tasks = list_tasks(listwatcher)
    # @show tasks
    
    # check if task in in current cache otherwise send to chan
    for taskid in keys(tasks)
        task = tasks[taskid]
        existing = get(listwatcher.tasks, task["metadata"]["uid"], Dict{String, Any}())
        if length(existing) == 0
            println("sending to queue!")
            put!(listwatcher.chan, task)
            listwatcher.tasks[taskid] = task
        end
    end
    # check if any current tasks no longer exist, if so send to chan
    for taskid in keys(listwatcher.tasks)
        task = listwatcher.tasks[taskid]
        existing = get(tasks, task["metadata"]["uid"], Dict{String, Any}())
        if length(existing) == 0
            println("sending to queue!!")
            put!(listwatcher.chan, task)
            delete!(listwatcher.tasks, taskid)
        end
    end
end

function loop(listwatcher::TaskListWatcher, interval::Dates.Second)
    println("starting loop...")
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
    @show resp
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

"""
    EventHandler(add::Function(Dict{String, Any}), 
            update::Function(Dict{String, Any}), 
            delete::Function(Dict{String, Any})
            )

An EventHandler can be registered with the informer to handle event actions.
"""
struct EventHandler
    add::Function(Dict{String, Any})
    update::Function(Dict{String, Any})
    delete::Function(Dict{String, Any})
    function EventHandler(add::Function(Dict{String, Any}), 
            update::Function(Dict{String, Any}), 
            delete::Function(Dict{String, Any})
            )
        new(add, update, delete)
    end
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
    eventhandler::EventHandler
    function TaskInformer(listwatcher::TaskListWatcher, chan::Channel)
        new(listwatcher, chan)
    end
end

function run(taskInformer::TaskInformer)
    println("running async")
    @async loop(taskInformer.listwatcher, Dates.Second(2))
    while true
        println("taking from chan")
        data = take!(taskInformer.chan)
        @show data
        dispatch(taskInformer.listwatcher, data)
    end
end

function dispatch(listwatcher::TaskListWatcher, task::Dict{String, Any})
    found = get_task(listwatcher, task["metadata"]["name"], task["metadata"]["namespace"])
    # task is missing
    if length(found) == 0
        println("deleting task: ", task)
        # should somehow use multiple dispatch here
        listwatcher.eventhandler.delete(task)
        return
    end
    # task is present, check if ids match
    if task["metadata"]["uid"] != found["metadata"]["uid"]
        println("updating task: ", task)
        listwatcher.eventhandler.update(task)
        return
    end
    # uids and names match, its an add
    println("adding task: ", task)
    listwatcher.eventhandler.add(task)
    return
end

