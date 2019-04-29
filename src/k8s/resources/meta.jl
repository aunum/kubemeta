mutable struct TypeMeta
    group::String
    version:::String
    kind::String
end

mutable struct ObjectMeta
    name::String
    namesapce:::String
    uid::String
    resourceversion::String
    labels::Dict{String, String}
    annotations::Dict{String, String}
end