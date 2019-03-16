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
    println(tasks)
    
    # check if task in in current cache otherwise send to chan
    for task in tasks
        existing = get(listwatcher.tasks, task["metadata"]["uid"], Dict{String, Any}())
        if length(existing) == 0
            put!(listwatcher.chan, task)
            listwatcher.tasks[task["metadata"]["uid"]] = task
        end
    end
    # check if any current tasks no longer exist, if so send to chan
    for task in listwatcher.tasks
        existing = get(tasks, task["metadata"]["uid"], Dict{String, Any}())
        if length(existing) == 0
            put!(listwatcher.chan, task)
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

function list_tasks(listwatcher::TaskListWatcher)::Dict{String,Any}
    resp = request(listwatcher.client, "GET", "/apis/kubemeta.ai/v1alpha1/tasks")
    str = String(resp.body)
    jobj = JSON.Parser.parse(str)
    @show jobj
    currentTasks = Dict{String, Any}()
    for item in jobj["items"]
        uid = item["metadata"]["uid"]
        currentTasks[uid] = item
    end
    return currentTasks
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
    function TaskInformer(listwatcher::TaskListWatcher, chan::Channel)
        new(listwatcher, chan)
    end
end

function run(taskInformer::TaskInformer)
    println("running async")
    @async loop(taskInformer.listwatcher)
    while true
        println("taking from the chan")
        data = take!(taskInformer.chan)
        @show data
    end
end
