module KubeMeta

include("client.jl")
include("informer.jl")
include("controller.jl")

export TaskController, run, K8sClient, request

end # module
