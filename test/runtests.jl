using KubeMeta, Test

@testset "kubeconfig connect" begin
    ctx = kubeconfig_client("")
    println("ctx: ", ctx)
end
