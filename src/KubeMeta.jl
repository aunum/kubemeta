module KubeMeta

include("client.jl")
include("informer.jl")
include("controller.jl")

export TaskListWatcher, TaskInformer, run, K8sClient, request, client

include("controllers/Controllers.jl")
using .Controllers
export Controller, DifferentiableController, DifferentiableAgent, add_task, update_task, delete_task

end # module
