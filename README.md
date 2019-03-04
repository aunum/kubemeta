# kubemeta
A meta-learning platform for Kubernetes

*"life is a complex nesting of organization at different levels and scales"*
## Overview
Kubemeta aims to be a compositional way of creating [meta-learning](https://arxiv.org/abs/1810.03548) environments on Kubernetes that foster [AutoML](https://github.com/hibayesian/awesome-automl-papers).

### Tasks

```yaml
apiVersion: kubemeta.ai/v1alpha1
kind: Task
metadata:
  name: dog-classifier
  labels:
    type: image
spec:
  description: classify dogs in images by breed
  input:
    image:
      type: text
      format: binary
  output:
    breedId:
      type: integer
```
A Task defines a piece of work as an input and output described in [OpenAPI format](https://swagger.io/specification/).

A controller will learn to complete Tasks using meta-learning algorithms that create machine learning solutions as Kubernetes objects.

## Running

The easiest way to test is using [kind](https://github.com/kubernetes-sigs/kind). Follow the instructions on the main page to get kind working.

Once kind is installed a cluster can be created using:
```sh
make cluster-up
```
