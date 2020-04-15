
@testset "Constructors" begin
    block = DCTBlock{Float32}(1:64)
    @test block[3, 7] == 42.0f0
    @test block[42] == 42.0f0
end

@testset "Traits" begin
    block = DCTBlock{Float32}(1:64)
    @test sizeof(DCTBlock{Float32}) == 64 * 4
    @test sizeof(block) == 64 * 4
    @test length(block) == 64
    @test size(block) == (8, 8)
end

@testset "Functions" begin
    block = DCTBlock{Float32}(1:64)
    mat = collect(block)
    @test mat isa Matrix{Float32}
    @test mat[3, 7] == 42.0f0
end
