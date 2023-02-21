# SimpleUnderscores.jl

SimpleUnderscores.jl aims to provide yet another way to locally construct anonymous functions where the arguments do not need to be listed before they are used in the body, but taking an approach that differents from [Underscores.jl](https://github.com/c42f/Underscores.jl) with less complicated scoping rules. See also [JuliaLang/julia/issues/38713](https://github.com/JuliaLang/julia/issues/38713).

By default, it exports one macro, `@->`. An expression acted on by `@->` interprets underscores `_` as a placeholder for a function argument. Hence, `@-> _ + 1` means the same thing as `x -> x + 1`. A bare underscore `_` always is the first argument to the function:
``` julia
julia> using SimpleUnderscores

julia> map(@-> _ + _, [1,2,3])
3-element Vector{Int64}:
 2
 4
 6
```

If you want to write a function acting on multiple arguments, you can write for instance `_4` to mean the fourth argument. The function returned will take as many arguments as the highest argument placeholder number specified.

``` julia
julia> λ = @-> _ + _3;

julia> λ(5, 6, 7)
12

julia> λ(5,6)
ERROR: MethodError: no method matching (::var"#23#24")(::Int64, ::Int64)
Closest candidates are:
  (::var"#23#24")(::Any, ::Any, ::Any)

```
```julia
julia> map(@-> _1.a + _2.b, [(;a=1,), (;a=2)], [(;b=3), (;b=4)])
2-element Vector{Int64}:
 4
 6
```

Macros appearing inside a `@->` macro are recursively hit with `macroexpand` in the approporiate module, this is to make sure that things like `@-> filter(@-> _.a > 1, _)` correctly work.

There's a second, unexported macro `@_` which is the exact same as `@->` but some people may prefer the name. If you prefer that, then you can simply do `using SimpleUnderscores: @_`.

### Caveats
Because the parser is such that [commas parse tighter than macros](https://github.com/JuliaLang/julia/issues/36547#issuecomment-1437406477), when you write code like

``` julia
map(@-> _ + _, [1, 2])
```
this will actually get parsed as `map(@->(((_ + _), [1, 2])))` rather than `map(@->(_ + _), [1, 2])`, but SimpleUnderscores will then macroexpand this to something like `map(((x -> x + x), [1, 2])...,)` so that we get the desired behaviour. This may cause some confusion if you are writing a macro that is operating on code which contains the `@->` macro. It also unfortunately means that a somewhat confusing error gets thrown if you try to construct a `Tuple` at the top level containing `@->`:

``` julia
julia> @-> _, [1] # Doesn't work :(
ERROR: syntax: "..." expression outside call around REPL[39]:1
   
julia> (@-> _, [1]) # Also doesn't work :(((
ERROR: syntax: "..." expression outside call around REPL[40]:1
   
julia> ((@-> _, [1]),) # At least this works.
(var"#31#32"(), [1])
```
but you should probably just use `@->( ... )` instead in these case.

If [julia/issues/48738](https://github.com/JuliaLang/julia/issues/48738) is resolved, then that should fix this.
