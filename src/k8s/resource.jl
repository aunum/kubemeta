import JSON2

include("client.jl")

```
    Resource(kind::String,
    version::String,
    group::String,
    namespaced::Bool,
    schema::Dict{String, Any})

A Resource represents a Kubernetes resource, it can be a CRD or core resource.
https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/
```
mutable struct Resource
    kind::String
    plural::String
    version::String
    group::String
    namespaced::Bool
    schema::Dict{String, Any}
    type
end

function parse(filepath::String)::Resource
end

function install(client::K8sClient, resource::Resource)
end

function get(client::K8sClient, resource::Resource, name::String)::Dict{String, Any}
    uri = ""
    if resource.group == "core"
        uri = joinpath("/api/", resource.version, resource.plural, name)
    else
        uri = joinpath("/apis/", resource.group, resource.version, resource.plural, name)
    end
    resp = request(client, "GET", uri)
    str = String(resp.body)
    jobj = JSON2.Parser.parse(str)
    return jobj
end

function get(client::K8sClient, resource::Resource, name::String, namespace::String)::Dict{String, Any}
    uri = ""
    if resource.group == "core"
        uri = joinpath("/api/", resource.version, "namespaces", namespace, resource.plural, name)
    else
        uri = joinpath("/apis/", resource.group, resource.version, "namespaces", namespace, resource.plural, name)
    end
    resp = request(client, "GET", uri)
    str = String(resp.body)
    jobj = JSON2.Parser.parse(str)
    return jobj
end

function list(client::K8sClient, resource::Resource; labels::Dict{String, Any}=Nothing)::Dict{String, Any}
    uri = ""
    if resource.group == "core"
        uri = joinpath("/api/", resource.version, resource.plural)
    else
        uri = joinpath("/apis/", resource.group, resource.version, resource.plural)
    end
    resp = request(client, "GET", uri)
    str = String(resp.body)
    jobj = JSON2.Parser.parse(str)
    return jobj
end

function list(client::K8sClient, resource::Resource, namespace::String; labels::Dict{String, Any}=Nothing)::Dict{String, Any}
    uri = ""
    if resource.group == "core"
        uri = joinpath("/api/", resource.version, "namespaces", namespace, resource.plural)
    else
        uri = joinpath("/apis/", resource.group, resource.version, "namespaces", namespace, resource.plural)
    end
    resp = request(client, "GET", uri)
    str = String(resp.body)
    jobj = JSON2.Parser.parse(str)
    return jobj
end

function create(client::K8sClient, resource::Resource, namespace::String, spec::Dict{String, Any})::Dict{String, Any}
    uri = ""
    if resource.group == "core"
        uri = joinpath("/api/", resource.version, "namespaces", namespace, resource.plural)
    else
        uri = joinpath("/apis/", resource.group, resource.version, "namespaces", namespace, resource.plural)
    end
    bod = JSON2.write(spec)
    resp = request(client, "POST", uri, bod)
    str = String(resp.body)
    jobj = JSON2.Parser.parse(str)
    return jobj
end

function create(client::K8sClient, resource::Resource, spec::Dict{String, Any})::Dict{String, Any}
    uri = ""
    if resource.group == "core"
        uri = joinpath("/api/", resource.version, resource.plural)
    else
        uri = joinpath("/apis/", resource.group, resource.version, resource.plural)
    end
    bod = JSON2.write(spec)
    resp = request(client, "POST", uri, bod)
    str = String(resp.body)
    jobj = JSON2.Parser.parse(str)
    return jobj
end

function update(client::K8sClient, resource::Resource, spec::Dict{String, Any})::Dict{String, Any}
    uri = ""
    if resource.group == "core"
        uri = joinpath("/api/", resource.version, resource.plural)
    else
        uri = joinpath("/apis/", resource.group, resource.version, resource.plural)
    end
    bod = JSON2.write(spec)
    resp = request(client, "PATCH", uri, bod)
    str = String(resp.body)
    jobj = JSON2.Parser.parse(str)
    return jobj
end

function update(client::K8sClient, resource::Resource, namespace::String, spec::Dict{String, Any})::Dict{String, Any}
    uri = ""
    if resource.group == "core"
        uri = joinpath("/api/", resource.version, "namespaces", namespace, resource.plural)
    else
        uri = joinpath("/apis/", resource.group, resource.version, "namespaces", namespace, resource.plural)
    end
    bod = JSON2.write(spec)
    resp = request(client, "PATCH", uri, bod)
    str = String(resp.body)
    jobj = JSON2.Parser.parse(str)
    return jobj
end

function delete(client::K8sClient, resource::Resource, name::String)::Dict{String, Any}
    uri = ""
    if resource.group == "core"
        uri = joinpath("/api/", resource.version, resource.plural)
    else
        uri = joinpath("/apis/", resource.group, resource.version, resource.plural)
    end
    resp = request(client, "DELETE", uri)
    str = String(resp.body)
    jobj = JSON2.Parser.parse(str)
    return jobj
end

function delete(client::K8sClient, resource::Resource, name::String, namespace::String)::Dict{String, Any}
    if resource.group == "core"
        uri = joinpath("/api/", resource.version, "namespaces", namespace, resource.plural)
    else
        uri = joinpath("/apis/", resource.group, resource.version, "namespaces", namespace, resource.plural)
    end
    resp = request(client, "DELETE", uri)
    str = String(resp.body)
    jobj = JSON2.Parser.parse(str)
    return jobj
end
