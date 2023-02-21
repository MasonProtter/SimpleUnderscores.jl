using Test
using SimpleUnderscores: @>, @_

@testset "Tests" begin
    f = @_  _ + _
    g = @> _ + _
    @test f(3) == g(3) == 6

    v = [(;a = i) for i ∈ -5:5]
    @test (v |> @> filter(@> _.a > 1, _)) == [(;a = a) for a ∈ -5:5 if a > 1]
    @test map(@_ 1 + _2, [1, 2, 3], [4, 5, 6]) == [5, 6, 7]
    h = @_ _ + _4
    @test_throws MethodError h(1, 2)
    @test h(1,2,3,4) == 5
    @test_throws MethodError h(1, 2, 3, 4, 5)
end
