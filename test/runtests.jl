using KubeMeta, Test

@testset "kubeconfig connect" begin
    c = TaskController("")
    KubeMeta.run(c)
end
