import HTTP, DataStructures

include("informer.jl")
include("client.jl")

"""
    TaskController(kubeconfigpath::String)

Operates on Task CRDs, will use kubeconfig file for k8s connection if given, otherwise
will attempt to find from environment.
"""
mutable struct TaskController
    client::K8sClient
    informer::TaskInformer
    function TaskController(kubeconfigpath::String)
        cli = Any
        if kubeconfigpath == ""
            cli = client()
        else
            cli = client(kubeconfigpath)
        end
        chan = Channel(32)
        lw = TaskListWatcher(cli, chan)
        informer = TaskInformer(lw, chan)
        new(cli, informer)
    end
end

function run(controller::TaskController)
    res = run(controller.informer)
    @show res
    typeof(res)
end
