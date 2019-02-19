# kubemeta
A meta-learning platform for Kubernetes

## Overview
Kubemeta aims to be a compositional way of creating [meta-learning](https://arxiv.org/abs/1810.03548) environments on Kubernetes that foster [AutoML](https://github.com/hibayesian/awesome-automl-papers).

### Controller
```yaml
apiVersion: kubemeta.ai/v1alpha1
kind: Controller
metadata:
  name: meta-learner1
spec:
  algorithm: "MCTS"
  selector:
    type: image
```
The controller will learn to complete Tasks using meta-learning algorithms that create machine learning solutions as Kubernetes objects.
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
