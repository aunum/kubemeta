using KubeMeta, Test

@testset "differentiable controller" begin
    chan = Channel(32)
    cli = client()
    lw = TaskListWatcher(cli, chan)
    controller = DifferentiableController()
    informer = TaskInformer(lw, chan, controller)
    KubeMeta.run(informer)
end
