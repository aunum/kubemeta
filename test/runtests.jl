using KubeMeta, Test

@testset "kubeconfig connect" begin
    chan = Channel(32)
    cli = client()
    lw = TaskListWatcher(cli, chan)
    controller = DifferentiableController()
    informer = TaskInformer(lw, chan, controller)
    KubeMeta.run(informer)
end
