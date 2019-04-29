module K8s

include("client.jl")
include("informer.jl")
include("crd.jl")
include("core.jl")

export TaskListWatcher, TaskInformer, run, K8sClient, request, client

end # module
