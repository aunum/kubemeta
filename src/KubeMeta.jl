module KubeMeta

include("client.jl")
include("controller.jl")

export discover_client, kubeconfig_client, incluster_client

end # module
