module SimpleUnderscores

export @_, @->

using MacroTools

function _underscore(ex, __module__)
    arity = 1
    if ex isa Expr && ex.head == :tuple
        pre_body, rest... = ex.args
    else
        pre_body = ex
        rest = ()
    end
    body = MacroTools.prewalk(pre_body) do ex
        if ex isa Expr && ex.head == :macrocall
            macroexpand(__module__, ex)
        elseif ex == :_
            ex = :_1 # turn :_ into :_1
        elseif ex isa Symbol
            s = String(ex)
            if !isnothing(match(r"^_[0-9]+$", s))
                n = parse(Int, s[2:end])
                arity = max(arity, n)
            end
            ex
        else
            ex
        end
    end
    args = Expr(:tuple, (Symbol(:_, n) for n ∈ 1:arity)...)
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

end # module SimpleUnderscores
