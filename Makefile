.PHONY: cluster-up cluster-down generate

cluster-up:
	kind create cluster --config kind-config.yaml
	KUBECONFIG="$(kind get kubeconfig-path --name="kind")" kubectl apply -f crd.yaml

cluster-down:
	kind delete cluster

generate:
	# TODO: get rid of this java garbage
	docker build -f Dockerfile.gen -t kubemeta.ai/gen:latest .
	docker run  --mount type=bind,src=`pwd`,dst=/julia -w / kubemeta.ai/gen:latest /bin/bash -c \
	"cd /Swagger.jl && julia --version && ls && plugin/build.sh && ls /Swagger.jl && /Swagger.jl/plugin/generate.sh -i /julia/open-api.yaml -o /julia/gen"
