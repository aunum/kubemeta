.PHONY: cluster-up

cluster-up:
	kind create cluster --config kind-config.yaml

cluster-down:
	kind delete cluster
