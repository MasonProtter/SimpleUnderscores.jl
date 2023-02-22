# SimpleUnderscores.jl

SimpleUnderscores.jl aims to provide yet another way to locally construct anonymous functions where the arguments do not need to be listed before they are used in the body, but taking an approach that differents from [Underscores.jl](https://github.com/c42f/Underscores.jl) with less complicated scoping rules. See also [JuliaLang/julia/issues/38713](https://github.com/JuliaLang/julia/issues/38713).

By default, it exports one macro, `@>`. An expression acted on by `@>` interprets underscores `_` as a placeholder for a function argument. Hence, `@> _ + 1` means the same thing as `x -> x + 1`. A bare underscore `_` always is the first argument to the function:
``` julia
julia> using SimpleUnderscores

julia> map(@> _ + _, [1,2,3])
3-element Vector{Int64}:
 2
 4
 6
```

### Multiple Arguments

<details>
<summary>Click to expand</summary>

If you want to write a function acting on multiple arguments, you can write for instance `_4` to mean the fourth argument. The function returned will take as many arguments as the highest argument placeholder number specified.

``` julia
julia> λ = @> _ + _3;

julia> λ(5, 6, 7)
12

julia> λ(5,6)
ERROR: MethodError: no method matching (::var"#23#24")(::Int64, ::Int64)
Closest candidates are:
  (::var"#23#24")(::Any, ::Any, ::Any)

```
```julia
julia> map(@> _1.a + _2.b, [(;a=1,), (;a=2)], [(;b=3), (;b=4)])
2-element Vector{Int64}:
 4
 6
```

You can also use `__` to signify varargs:

``` julia
julia> f = @> _ + __[end];

julia> f(1,2,3,4,5,6,7,8,9)
10
```

</details>

### Main limitation: dealing with tuples and commas
<details>
<summary>Click to expand</summary>
Because the parser is such that [commas parse tighter than macros](https://github.com/JuliaLang/julia/issues/36547#issuecomment-1437406477), when you write code like

``` julia
map(@> _ + _, [1, 2])
```
this will actually get parsed as `map(@>(((_ + _), [1, 2])))` rather than `map(@>(_ + _), [1, 2])`, but SimpleUnderscores will then macroexpand this to something like `map(((x -> x + x), [1, 2])...,)` so that we get the desired behaviour. 

Unfortunately though, SimpleUnderscores.jl cannot tell the difference between `@> (_, 1)` and `(@> _, 1)`, which means that if you want to write an anonymous function using SimpleUnderscores.jl that returns a `Tuple`, you need to write something like `@> tuple(_, 1)`. The potential for fixing this is being discussed here:  [JuliaLang/julia/issues/36547](https://github.com/JuliaLang/julia/issues/36547).

This parsing behaviour also unfortunately means that a somewhat confusing error gets thrown if you try to construct a `Tuple` at the top level containing `@>`:

``` julia
julia> @> _, [1] # Doesn't work :(
ERROR: syntax: "..." expression outside call around REPL[39]:1
   
julia> (@> _, [1]) # Also doesn't work :(((
ERROR: syntax: "..." expression outside call around REPL[40]:1
   
julia> ((@> _, [1]),) # At least this works.
(var"#31#32"(), [1])
```
but you should probably just use `@>( ... )` instead in these case. Follow this PR for any news on a potential fix: [JuliaLang/julia/pull/48750](https://github.com/JuliaLang/julia/pull/48750)

</details>



### Nested macros
<details>
<summary>Click to expand</summary>

Macros appearing inside a `@>` macro are recursively hit with `macroexpand` in the approporiate module, this is to make sure that things like `@> filter(@> _.a > 1, _)` correctly work.

</details>

### Other names
<details>
<summary>Click to expand</summary>

There's two other, unexported macros inside the package, `@->` and `@_` which are the exact same as `@>` but some people may prefer the other names. If you prefer that, then you can simply do `using SimpleUnderscores: @_` or `using SimpleUnderscores: @->`.

</details>
