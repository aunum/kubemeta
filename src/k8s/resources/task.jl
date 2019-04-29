include("meta.jl")

mutable struct TaskSpec
    input::Dict{String, Any}
    output::Dict{String, Any}
    error::Dict{String, Any}
end

mutable struct TaskStatus
    status::Dict{String, Any}
end

mutable struct Task
    typemeta::TypeMeta
    objectmeta::ObjectMeta
    spec::TaskSpec
    status::TaskStatus
end

function convert(object::Dict{String, Any}, task::Task)

end