module SimpleUnderscores

export @>

using MacroTools

if !isdefined(SimpleUnderscores, :isnothing)
    isnothing(x) = x === nothing
end

function _underscore(ex, __module__)
    arity = 0
    has_vararg = false
    tag = gensym()
    if ex isa Expr && ex.head == :tuple
        pre_body, rest = ex.args[1], ex.args[2:end]
    else
        pre_body = ex
        rest = []
    end
    body = MacroTools.prewalk(pre_body) do ex
        if ex isa Expr && ex.head == :macrocall
            macroexpand(__module__, ex)
        elseif ex == :_
            ex = :_1 # turn :_ into :_1
            arity = max(arity, 1)
            Symbol(ex, tag)
        elseif ex == :__
            has_vararg = true
            Symbol(:args, tag)
        elseif ex isa Symbol
            s = String(ex)
            if !isnothing(match(r"^_[0-9]+$", s))
                n = parse(Int, s[2:end])
                arity = max(arity, n)
                Symbol(ex, tag)
            else
                ex
            end
        else
            ex
        end
    end
    args = Expr(:tuple, (Symbol(:_, n, tag) for n ∈ 1:arity)...)
    if has_vararg
        push!(args.args, :($(Symbol(:args, tag))...))
    end
    λ = :($args -> $body)
    if length(rest) == 0
        λ
    else
        :(($λ, $(rest...))...)
    end
end

@eval macro $(:_)(ex)
    esc(_underscore(ex, __module__))
end

@eval macro $(Symbol("->"))(ex)
    esc(_underscore(ex, __module__))
end

macro (>)(ex)
    esc(_underscore(ex, __module__))
end

end # module SimpleUnderscores
