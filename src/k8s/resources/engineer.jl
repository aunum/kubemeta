include("meta.jl")

mutable struct EngineerSpec
    input::Dict{String, Any}
    output::Dict{String, Any}
    error::Dict{String, Any}
end

mutable struct EngineerStatus
    status::Dict{String, Any}
end

mutable struct Engineer
    typemeta::TypeMeta
    objectmeta::ObjectMeta
    spec::EngineerSpec
    status::EngineerStatus
end
